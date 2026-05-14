// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QSortFilterProxyModel>
#include <QObject>
#include <QString>
#include <QStringList>


class SeminarSortProxyModel : public QSortFilterProxyModel {

    Q_OBJECT
    Q_PROPERTY(bool sortByDistance READ sortByDistance WRITE setSortByDistance NOTIFY sortByDistanceChanged)
    Q_PROPERTY(QStringList eventTypeFilters READ eventTypeFilters WRITE setEventTypeFilters NOTIFY eventTypeFiltersChanged)
    Q_PROPERTY(double maxDistanceKm READ maxDistanceKm WRITE setMaxDistanceKm NOTIFY maxDistanceKmChanged)

public:
    explicit SeminarSortProxyModel(QObject *parent = nullptr);

    bool sortByDistance() const;

    void setSortByDistance(bool value);

    QStringList eventTypeFilters() const;

    void setEventTypeFilters(const QStringList &values);

    double maxDistanceKm() const;

    void setMaxDistanceKm(double value);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

signals:
    void sortByDistanceChanged();
    void eventTypeFiltersChanged();
    void maxDistanceKmChanged();

private:
    bool m_sortByDistance = true;
    double m_maxDistanceKm = -1.0;
    QStringList m_eventTypeFilters = {
        "seminar",
        "competition",
        "national_team",
        "regional_team",
        "training"
    };

    int roleForName(const QByteArray &name) const;
};
