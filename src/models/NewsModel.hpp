// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QAbstractListModel>
#include <QList>


class NewsModel : public QAbstractListModel {

    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        DateRole,
        DescriptionRole,
        UrlRole,
        ImageUrlRole,
        CategoryRole,
        ItemTypeRole
    };

    explicit NewsModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const;

    Q_INVOKABLE void clear();
    Q_INVOKABLE void appendFromJson(const QString &json);

signals:
    void countChanged();

private:
    struct NewsItem {
        QString title;
        QString date;
        QString description;
        QString url;
        QString imageUrl;
        QString category;
        QString itemType;
    };

    QList<NewsItem> m_items;
};
