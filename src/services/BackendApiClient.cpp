// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "BackendApiClient.hpp"

#include "BackendConfig.hpp"
#include "utils/Logger.hpp"

#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include <QUrlQuery>

namespace {
}

BackendApiClient::BackendApiClient(QObject *parent)
    : QObject(parent) {
}

bool BackendApiClient::dojoLoading() const {
    return m_dojoLoading;
}

QString BackendApiClient::dojoErrorString() const {
    return m_dojoErrorString;
}

void BackendApiClient::loadAppointments() {
    getJson(
        QStringLiteral("/appointments"),
        [this](const QString &json) {
            emit appointmentsLoaded(json);
        },
        [this](const QString &error) {
            LOG_WARN << "Appointments backend request failed:" << error;
            emit appointmentsFailed(error);
        }
    );
}

void BackendApiClient::loadDojos() {
    if (m_dojoLoading)
        return;

    LOG_INFO << "Loading dojos from backend ...";
    setDojoErrorString({});
    setDojoLoading(true);

    getJson(
        QStringLiteral("/dojos"),
        [this](const QString &json) {
            setDojoLoading(false);
            emit dojosLoaded(json);
        },
        [this](const QString &error) {
            setDojoErrorString(error);
            setDojoLoading(false);
        }
    );
}

void BackendApiClient::geocodeLocation(
    const QString &requestId,
    const QString &query,
    const QString &fallbackQuery
) {
    const QString trimmedQuery = query.simplified();
    if (requestId.isEmpty() || trimmedQuery.isEmpty()) {
        emit locationGeocoded(requestId, 0.0, 0.0, false);
        return;
    }

    QUrl url(BackendConfig::BaseUrl + QStringLiteral("/geocode"));
    QUrlQuery urlQuery;
    urlQuery.addQueryItem(QStringLiteral("q"), trimmedQuery);
    const QString trimmedFallbackQuery = fallbackQuery.simplified();
    if (!trimmedFallbackQuery.isEmpty() && trimmedFallbackQuery != trimmedQuery)
        urlQuery.addQueryItem(QStringLiteral("fallback"), trimmedFallbackQuery);
    url.setQuery(urlQuery);

    LOG_DEBUG << "Backend geocode request:" << requestId << trimmedQuery;

    QNetworkRequest request{url};
    BackendConfig::applyDefaultHeaders(request);

    QNetworkReply *reply = m_networkAccessManager.get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestId]() {
        reply->deleteLater();

        const QByteArray body = reply->isOpen() ? reply->readAll() : QByteArray();
        if (reply->error() != QNetworkReply::NoError) {
            LOG_WARN << "Backend geocode request failed:"
                     << reply->url().toString()
                     << "error=" << reply->errorString();
            emit locationGeocodeFailed(requestId, reply->errorString());
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(body);
        if (!document.isObject()) {
            emit locationGeocodeFailed(requestId, QStringLiteral("Geocode response is not a JSON object"));
            return;
        }

        const QJsonObject object = document.object();
        const bool found = object.value(QStringLiteral("found")).toBool();
        emit locationGeocoded(
            requestId,
            object.value(QStringLiteral("latitude")).toDouble(),
            object.value(QStringLiteral("longitude")).toDouble(),
            found
        );
    });
}

void BackendApiClient::getJson(
    const QString &path,
    const std::function<void(const QString &)> &success,
    const std::function<void(const QString &)> &failure
) {
    const QUrl url(BackendConfig::BaseUrl + path);
    LOG_DEBUG << "Backend request:" << url.toString();

    QNetworkRequest request{url};
    BackendConfig::applyDefaultHeaders(request);

    QNetworkReply *reply = m_networkAccessManager.get(request);
    connect(reply, &QNetworkReply::finished, this, [reply, success, failure]() {
        reply->deleteLater();

        const QByteArray body = reply->isOpen() ? reply->readAll() : QByteArray();
        if (reply->error() != QNetworkReply::NoError) {
            LOG_WARN << "Backend request failed:"
                     << reply->url().toString()
                     << "error=" << reply->errorString();
            failure(reply->errorString() + QStringLiteral(": ") + QString::fromUtf8(body.left(300)));
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(body);
        if (!document.isArray()) {
            failure(QStringLiteral("Backend response is not a JSON array"));
            return;
        }

        success(QString::fromUtf8(document.toJson(QJsonDocument::Compact)));
    });
}

void BackendApiClient::setDojoLoading(bool loading) {
    if (m_dojoLoading == loading)
        return;

    m_dojoLoading = loading;
    emit dojoLoadingChanged();
}

void BackendApiClient::setDojoErrorString(const QString &errorString) {
    if (m_dojoErrorString == errorString)
        return;

    m_dojoErrorString = errorString;
    emit dojoErrorStringChanged();
}
