// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QAbstractListModel>
#include <QList>


class DojoModel : public QAbstractListModel {

    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        StreetRole,
        ZipCityRole,
        WebsiteRole,
        EmailRole,
        PhoneRole,
        ContactRole,
        NotesRole,
        ImageUrlRole,
        LatitudeRole,
        LongitudeRole,
        HasCoordinateRole
    };

    explicit DojoModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const;

    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE void updateCoordinate(int id, double latitude, double longitude);

public slots:
    void loadFromJson(const QString &json);

signals:
    void countChanged();

private:
    struct DojoItem {
        int id = -1;
        QString title;
        QString street;
        QString zipCity;
        QString website;
        QString email;
        QString phone;
        QString contact;
        QString notes;
        QString imageUrl;
        double latitude = 0.0;
        double longitude = 0.0;
        bool hasCoordinate = false;
    };

    QList<DojoItem> m_items;
};
