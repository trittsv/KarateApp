// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "DojoSortProxyModel.hpp"


DojoSortProxyModel::DojoSortProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent) {
    setDynamicSortFilter(true);
    sort(0, Qt::AscendingOrder);
}

QString DojoSortProxyModel::searchText() const {
    return m_searchText;
}

void DojoSortProxyModel::setSearchText(const QString &searchText) {
    const QString normalized = searchText.simplified();
    if (m_searchText == normalized)
        return;

    m_searchText = normalized;
    emit searchTextChanged();
    beginFilterChange();
    endFilterChange(Direction::Rows);
}

bool DojoSortProxyModel::filterAcceptsRow(
    int sourceRow,
    const QModelIndex &sourceParent
) const {
    if (m_searchText.isEmpty())
        return true;

    const QModelIndex index = sourceModel()->index(
        sourceRow,
        0,
        sourceParent
    );
    const QString searchable = QStringLiteral("%1 %2 %3")
        .arg(
            sourceModel()->data(index, roleForName("title")).toString(),
            sourceModel()->data(index, roleForName("street")).toString(),
            sourceModel()->data(index, roleForName("zipCity")).toString()
        );
    return searchable.contains(m_searchText, Qt::CaseInsensitive);
}

bool DojoSortProxyModel::lessThan(
    const QModelIndex &left,
    const QModelIndex &right
) const {
    const int titleRole = roleForName("title");
    return QString::localeAwareCompare(
        sourceModel()->data(left, titleRole).toString(),
        sourceModel()->data(right, titleRole).toString()
    ) < 0;
}

int DojoSortProxyModel::roleForName(const QByteArray &name) const {
    if (!sourceModel())
        return -1;

    const auto roles = sourceModel()->roleNames();
    for (auto it = roles.cbegin(); it != roles.cend(); ++it) {
        if (it.value() == name)
            return it.key();
    }
    return -1;
}
