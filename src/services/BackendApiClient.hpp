// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QNetworkAccessManager>
#include <QObject>
#include <QString>

#include <functional>

class BackendApiClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool dojoLoading READ dojoLoading NOTIFY dojoLoadingChanged)
    Q_PROPERTY(QString dojoErrorString READ dojoErrorString NOTIFY dojoErrorStringChanged)

public:
    explicit BackendApiClient(QObject *parent = nullptr);

    bool dojoLoading() const;
    QString dojoErrorString() const;

    void loadAppointments();
    Q_INVOKABLE void loadDojos();
    Q_INVOKABLE void geocodeLocation(
        const QString &requestId,
        const QString &query,
        const QString &fallbackQuery = {}
    );

signals:
    void appointmentsLoaded(const QString &json);
    void appointmentsFailed(const QString &error);
    void dojosLoaded(const QString &json);
    void locationGeocoded(const QString &requestId, double latitude, double longitude, bool found);
    void locationGeocodeFailed(const QString &requestId, const QString &error);
    void dojoLoadingChanged();
    void dojoErrorStringChanged();

private:
    QNetworkAccessManager m_networkAccessManager;
    bool m_dojoLoading = false;
    QString m_dojoErrorString;

    void getJson(const QString &path, const std::function<void(const QString &)> &success, const std::function<void(const QString &)> &failure);
    void setDojoLoading(bool loading);
    void setDojoErrorString(const QString &errorString);
};
