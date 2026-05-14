// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "DjkbNewsScraper.hpp"

#include "BackendConfig.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include <QUrlQuery>

namespace {
QString backendError(QNetworkReply *reply, const QByteArray &body) {
    const QJsonDocument document = QJsonDocument::fromJson(body);
    if (document.isObject()) {
        const QString message = document.object().value("message").toString();
        if (!message.isEmpty())
            return message;
    }
    return reply->errorString();
}

QNetworkRequest backendRequest(const QString &path, const QUrlQuery &query = {}) {
    QUrl url(BackendConfig::BaseUrl + path);
    url.setQuery(query);

    QNetworkRequest request{url};
    BackendConfig::applyDefaultHeaders(request);
    return request;
}
}

DjkbNewsScraper::DjkbNewsScraper(QObject *parent)
    : QObject(parent) {
}

bool DjkbNewsScraper::loading() const { return m_loading; }
bool DjkbNewsScraper::hasMore() const { return m_hasMore; }
QString DjkbNewsScraper::errorString() const { return m_errorString; }
bool DjkbNewsScraper::detailLoading() const { return m_detailLoading; }
QString DjkbNewsScraper::detailErrorString() const { return m_detailErrorString; }

void DjkbNewsScraper::loadFirstPage() {
    loadSection(m_section);
}

void DjkbNewsScraper::loadSection(const QString &section) {
    m_section = section == QStringLiteral("results")
                    ? QStringLiteral("results")
                    : QStringLiteral("news");
    m_nextToken.clear();
    setHasMore(true);
    setErrorString({});
    fetchPage(++m_requestId);
}

void DjkbNewsScraper::loadMore() {
    if (m_loading || !m_hasMore)
        return;

    setErrorString({});
    fetchPage(m_requestId);
}

void DjkbNewsScraper::fetchPage(quint64 requestId) {
    setLoading(true);

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("section"), m_section);
    if (!m_nextToken.isEmpty())
        query.addQueryItem(QStringLiteral("token"), m_nextToken);

    QNetworkReply *reply = m_manager.get(backendRequest(QStringLiteral("/news"), query));
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestId]() {
        reply->deleteLater();
        if (requestId != m_requestId)
            return;

        const QByteArray body = reply->readAll();
        if (reply->error() != QNetworkReply::NoError) {
            setErrorString(backendError(reply, body));
            setLoading(false);
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(body);
        const QJsonObject object = document.object();
        const QJsonArray items = object.value(QStringLiteral("items")).toArray();
        m_nextToken = object.value(QStringLiteral("next_token")).toString();
        setHasMore(object.value(QStringLiteral("has_more")).toBool(!m_nextToken.isEmpty()));
        if (!items.isEmpty()) {
            emit pageLoaded(QString::fromUtf8(
                QJsonDocument(items).toJson(QJsonDocument::Compact)
            ));
        }
        setLoading(false);
    });
}

void DjkbNewsScraper::loadDetail(const QString &url) {
    if (m_detailLoading || url.isEmpty())
        return;

    setDetailErrorString({});
    setDetailLoading(true);

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("url"), url);
    QNetworkReply *reply = m_manager.get(backendRequest(QStringLiteral("/news/detail"), query));
    connect(reply, &QNetworkReply::finished, this, [this, reply, url]() {
        reply->deleteLater();
        const QByteArray body = reply->readAll();
        if (reply->error() != QNetworkReply::NoError) {
            setDetailErrorString(backendError(reply, body));
            setDetailLoading(false);
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(body);
        if (!document.isObject() || document.object().value(QStringLiteral("body")).toString().isEmpty()) {
            setDetailErrorString(QStringLiteral("Der Artikelinhalt konnte nicht gelesen werden."));
        } else {
            emit detailLoaded(
                url,
                QString::fromUtf8(document.toJson(QJsonDocument::Compact))
            );
        }
        setDetailLoading(false);
    });
}

void DjkbNewsScraper::setLoading(bool loading) {
    if (m_loading == loading)
        return;

    m_loading = loading;
    emit loadingChanged();
}

void DjkbNewsScraper::setHasMore(bool hasMore) {
    if (m_hasMore == hasMore)
        return;

    m_hasMore = hasMore;
    emit hasMoreChanged();
}

void DjkbNewsScraper::setErrorString(const QString &errorString) {
    if (m_errorString == errorString)
        return;

    m_errorString = errorString;
    emit errorStringChanged();
}

void DjkbNewsScraper::setDetailLoading(bool loading) {
    if (m_detailLoading == loading)
        return;

    m_detailLoading = loading;
    emit detailLoadingChanged();
}

void DjkbNewsScraper::setDetailErrorString(const QString &errorString) {
    if (m_detailErrorString == errorString)
        return;

    m_detailErrorString = errorString;
    emit detailErrorStringChanged();
}
