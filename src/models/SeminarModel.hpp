// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QAbstractListModel>
#include <QJsonArray>
#include <QJsonObject>
#include <QDate>
#include <QGeoCoordinate>


class SeminarModel : public QAbstractListModel {

    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        DateRole,
        CategoryRole,
        DojoRole,
        ContactRole,
        EmailRole,
        PhoneRole,
        PdfUrlRole,
        IcsUrlRole,
        StreetRole,
        ZipRole,
        CityRole,
        CountryRole,
        MapsUrlRole,
        LatitudeRole,
        LongitudeRole,
        HasCoordinateRole,
        DistanceKmRole,
        DistanceTextRole,
        EventTypeRole,
        EventTypeLabelRole,
        DateSortValueRole,
        IsOutdatedRole,
        AppointmentIdRole
    };

    explicit SeminarModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void loadFromJson(const QString &json);
    Q_INVOKABLE void updateCoordinate(int id, double latitude, double longitude);
    Q_INVOKABLE void updateUserPosition(double latitude, double longitude);
    Q_INVOKABLE QVariantMap getById(int seminarId) const;

signals:
    void countChanged();

private:
    struct Seminar {
        int id = -1;
        QString appointmentId;

        QString title;
        QString date;
        QString category;
        QString eventType = "seminar";
        QString dojo;
        QString contact;
        QString email;
        QString phone;
        QString pdfUrl;
        QString icsUrl;

        QString street;
        QString zip;
        QString city;
        QString country = "Germany";
        QString mapsUrl;

        double latitude = 0.0;
        double longitude = 0.0;
        bool hasCoordinate = false;

        double distanceKm = -1.0;
    };

    QList<Seminar> m_items;
    QGeoCoordinate m_userCoordinate;
    bool m_hasUserCoordinate = false;
    int m_nextId = 1;

    static QDate parseGermanDate(const QString &date);
    static QDate parseGermanEndDate(const QString &date);
    static bool isOutdated(const QString &date);
    static QString eventTypeLabel(const QString &eventType);
    QString distanceText(const Seminar &s) const;
    void updateDistance(Seminar &s);
    void sortItems();
    int rowById(int id) const;
};
