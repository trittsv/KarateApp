// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "DjkbGalleryScraper.hpp"

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

DjkbGalleryScraper::DjkbGalleryScraper(QObject *parent)
    : QObject(parent) {
}

bool DjkbGalleryScraper::yearsLoading() const { return m_yearsLoading; }
bool DjkbGalleryScraper::albumsLoading() const { return m_albumsLoading; }
bool DjkbGalleryScraper::photosLoading() const { return m_photosLoading; }
bool DjkbGalleryScraper::photosHasMore() const { return m_photosHasMore; }
QString DjkbGalleryScraper::yearsErrorString() const { return m_yearsErrorString; }
QString DjkbGalleryScraper::albumsErrorString() const { return m_albumsErrorString; }
QString DjkbGalleryScraper::photosErrorString() const { return m_photosErrorString; }

void DjkbGalleryScraper::loadYears() {
    if (m_yearsLoading)
        return;

    setYearsErrorString({});
    setYearsLoading(true);

    QNetworkReply *reply = m_manager.get(backendRequest(QStringLiteral("/gallery/years")));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        const QByteArray body = reply->readAll();
        if (reply->error() != QNetworkReply::NoError) {
            setYearsErrorString(backendError(reply, body));
        } else {
            const QJsonDocument document = QJsonDocument::fromJson(body);
            if (!document.isArray() || document.array().isEmpty())
                setYearsErrorString(QStringLiteral("Die verfügbaren Jahrgänge konnten nicht gelesen werden."));
            else
                emit yearsLoaded(QString::fromUtf8(document.toJson(QJsonDocument::Compact)));
        }
        setYearsLoading(false);
    });
}

void DjkbGalleryScraper::loadAlbums(const QString &url) {
    if (url.isEmpty())
        return;

    const quint64 requestId = ++m_albumRequestId;
    setAlbumsErrorString({});
    setAlbumsLoading(true);

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("url"), url);
    QNetworkReply *reply = m_manager.get(backendRequest(QStringLiteral("/gallery/albums"), query));
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestId]() {
        reply->deleteLater();
        if (requestId != m_albumRequestId)
            return;

        const QByteArray body = reply->readAll();
        if (reply->error() != QNetworkReply::NoError) {
            setAlbumsErrorString(backendError(reply, body));
        } else {
            const QJsonDocument document = QJsonDocument::fromJson(body);
            if (!document.isArray() || document.array().isEmpty())
                setAlbumsErrorString(QStringLiteral("Für diesen Jahrgang wurden keine Alben gefunden."));
            else
                emit albumsLoaded(QString::fromUtf8(document.toJson(QJsonDocument::Compact)));
        }
        setAlbumsLoading(false);
    });
}

void DjkbGalleryScraper::loadFirstPhotoPage(const QString &url) {
    if (url.isEmpty())
        return;

    const quint64 requestId = ++m_photoRequestId;
    m_nextPhotoPageUrl = url;
    setPhotosHasMore(true);
    setPhotosErrorString({});
    fetchPhotos(m_nextPhotoPageUrl, requestId);
}

void DjkbGalleryScraper::loadMorePhotos() {
    if (m_photosLoading || !m_photosHasMore || m_nextPhotoPageUrl.isEmpty())
        return;

    setPhotosErrorString({});
    fetchPhotos(m_nextPhotoPageUrl, m_photoRequestId);
}

void DjkbGalleryScraper::fetchPhotos(const QString &url, quint64 requestId) {
    setPhotosLoading(true);

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("url"), url);
    QNetworkReply *reply = m_manager.get(backendRequest(QStringLiteral("/gallery/photos"), query));
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestId]() {
        reply->deleteLater();
        if (requestId != m_photoRequestId)
            return;

        const QByteArray body = reply->readAll();
        if (reply->error() != QNetworkReply::NoError) {
            setPhotosErrorString(backendError(reply, body));
            setPhotosLoading(false);
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(body);
        const QJsonObject object = document.object();
        const QJsonArray items = object.value(QStringLiteral("items")).toArray();
        m_nextPhotoPageUrl = object.value(QStringLiteral("next_url")).toString();
        setPhotosHasMore(object.value(QStringLiteral("has_more")).toBool(!m_nextPhotoPageUrl.isEmpty()));
        if (items.isEmpty()) {
            setPhotosErrorString(QStringLiteral("Auf dieser Seite wurden keine Bilder gefunden."));
        } else {
            emit photosLoaded(QString::fromUtf8(
                QJsonDocument(items).toJson(QJsonDocument::Compact)
            ));
        }
        setPhotosLoading(false);
    });
}

void DjkbGalleryScraper::setYearsLoading(bool value) {
    if (m_yearsLoading == value) return;
    m_yearsLoading = value;
    emit yearsLoadingChanged();
}

void DjkbGalleryScraper::setAlbumsLoading(bool value) {
    if (m_albumsLoading == value) return;
    m_albumsLoading = value;
    emit albumsLoadingChanged();
}

void DjkbGalleryScraper::setPhotosLoading(bool value) {
    if (m_photosLoading == value) return;
    m_photosLoading = value;
    emit photosLoadingChanged();
}

void DjkbGalleryScraper::setPhotosHasMore(bool value) {
    if (m_photosHasMore == value) return;
    m_photosHasMore = value;
    emit photosHasMoreChanged();
}

void DjkbGalleryScraper::setYearsErrorString(const QString &value) {
    if (m_yearsErrorString == value) return;
    m_yearsErrorString = value;
    emit yearsErrorStringChanged();
}

void DjkbGalleryScraper::setAlbumsErrorString(const QString &value) {
    if (m_albumsErrorString == value) return;
    m_albumsErrorString = value;
    emit albumsErrorStringChanged();
}

void DjkbGalleryScraper::setPhotosErrorString(const QString &value) {
    if (m_photosErrorString == value) return;
    m_photosErrorString = value;
    emit photosErrorStringChanged();
}
