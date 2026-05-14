// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QAbstractListModel>
#include <QList>


class GalleryModel : public QAbstractListModel {

    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        TitleRole = Qt::UserRole + 1,
        DescriptionRole,
        UrlRole,
        ImageUrlRole,
        ThumbnailUrlRole,
        ItemCountRole
    };

    explicit GalleryModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const;

    Q_INVOKABLE void clear();
    Q_INVOKABLE void appendFromJson(const QString &json);
    Q_INVOKABLE QVariantMap get(int row) const;

signals:
    void countChanged();

private:
    struct Item {
        QString title;
        QString description;
        QString url;
        QString imageUrl;
        QString thumbnailUrl;
        int itemCount = 0;
    };

    QList<Item> m_items;
};
