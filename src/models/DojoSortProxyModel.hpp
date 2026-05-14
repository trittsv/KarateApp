// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QSortFilterProxyModel>


class DojoSortProxyModel : public QSortFilterProxyModel {

    Q_OBJECT
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)

public:
    explicit DojoSortProxyModel(QObject *parent = nullptr);

    QString searchText() const;
    void setSearchText(const QString &searchText);

signals:
    void searchTextChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
    QString m_searchText;

    int roleForName(const QByteArray &name) const;
};
