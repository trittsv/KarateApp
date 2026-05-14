// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "SeminarSortProxyModel.hpp"

#include <cmath>
#include <QModelIndex>

SeminarSortProxyModel::SeminarSortProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent) {
    setDynamicSortFilter(true);
    sort(0, Qt::AscendingOrder);
}

QStringList SeminarSortProxyModel::eventTypeFilters() const {
    return m_eventTypeFilters;
}

void SeminarSortProxyModel::setEventTypeFilters(const QStringList &values) {
    if (m_eventTypeFilters == values)
        return;

    m_eventTypeFilters = values;
    emit eventTypeFiltersChanged();

    invalidate();
}

bool SeminarSortProxyModel::sortByDistance() const {
    return m_sortByDistance;
}

void SeminarSortProxyModel::setSortByDistance(bool value) {

    if (m_sortByDistance == value)
        return;

    m_sortByDistance = value;
    emit sortByDistanceChanged();

    invalidate();
    sort(0, Qt::AscendingOrder);
}

double SeminarSortProxyModel::maxDistanceKm() const {
    return m_maxDistanceKm;
}

void SeminarSortProxyModel::setMaxDistanceKm(double value) {
    if (qFuzzyCompare(m_maxDistanceKm, value))
        return;

    m_maxDistanceKm = value;
    emit maxDistanceKmChanged();
    invalidate();
}

bool SeminarSortProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const {
    const int eventTypeRole = roleForName("eventType");
    if (eventTypeRole < 0)
        return true;

    const QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    if (!m_eventTypeFilters.contains(sourceModel()->data(index, eventTypeRole).toString()))
        return false;

    if (m_maxDistanceKm >= 0.0) {
        const int distanceRole = roleForName("distanceKm");
        if (distanceRole < 0)
            return false;

        const double distance = sourceModel()->data(index, distanceRole).toDouble();
        if (distance < 0.0 || !std::isfinite(distance))
            return false;

        return distance <= m_maxDistanceKm;
    }

    return true;
}

bool SeminarSortProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const {
    const int outdatedRole = roleForName("isOutdated");
    if (outdatedRole >= 0) {
        const bool leftOutdated = sourceModel()->data(left, outdatedRole).toBool();
        const bool rightOutdated = sourceModel()->data(right, outdatedRole).toBool();

        if (leftOutdated != rightOutdated)
            return !leftOutdated;
    }

    const int dateRole = roleForName("dateSortValue");
    const QString leftDate = dateRole >= 0
        ? sourceModel()->data(left, dateRole).toString()
        : QString();
    const QString rightDate = dateRole >= 0
        ? sourceModel()->data(right, dateRole).toString()
        : QString();

    const auto compareDates = [&]() {
        if (leftDate.isEmpty() != rightDate.isEmpty())
            return leftDate.isEmpty() ? 1 : -1;

        return QString::compare(leftDate, rightDate);
    };

    if (!m_sortByDistance) {
        const int dateComparison = compareDates();
        if (dateComparison != 0)
            return dateComparison < 0;

        return left.row() < right.row();
    }

    const int distanceRole = roleForName("distanceKm");

    const double leftDistance = sourceModel()->data(left, distanceRole).toDouble();
    const double rightDistance = sourceModel()->data(right, distanceRole).toDouble();

    if (leftDistance != rightDistance)
        return leftDistance < rightDistance;

    const int dateComparison = compareDates();
    if (dateComparison != 0)
        return dateComparison < 0;

    return left.row() < right.row();
}



int SeminarSortProxyModel::roleForName(const QByteArray &name) const
{
    if (!sourceModel())
        return -1;

    const auto roles = sourceModel()->roleNames();

    for (auto it = roles.begin(); it != roles.end(); ++it) {
        if (it.value() == name)
            return it.key();
    }

    return -1;
}
