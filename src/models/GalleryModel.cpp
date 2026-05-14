// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "GalleryModel.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>


GalleryModel::GalleryModel(QObject *parent)
    : QAbstractListModel(parent) {
}

int GalleryModel::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : static_cast<int>(m_items.size());
}

QVariant GalleryModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const Item &item = m_items[index.row()];
    switch (role) {
    case TitleRole: return item.title;
    case DescriptionRole: return item.description;
    case UrlRole: return item.url;
    case ImageUrlRole: return item.imageUrl;
    case ThumbnailUrlRole: return item.thumbnailUrl;
    case ItemCountRole: return item.itemCount;
    default: return {};
    }
}

QHash<int, QByteArray> GalleryModel::roleNames() const {
    return {
        { TitleRole, "title" },
        { DescriptionRole, "description" },
        { UrlRole, "url" },
        { ImageUrlRole, "imageUrl" },
        { ThumbnailUrlRole, "thumbnailUrl" },
        { ItemCountRole, "itemCount" }
    };
}

int GalleryModel::count() const {
    return static_cast<int>(m_items.size());
}

void GalleryModel::clear() {
    if (m_items.isEmpty())
        return;

    beginResetModel();
    m_items.clear();
    endResetModel();
    emit countChanged();
}

void GalleryModel::appendFromJson(const QString &json) {
    const QJsonDocument document = QJsonDocument::fromJson(json.toUtf8());
    if (!document.isArray())
        return;

    QSet<QString> knownUrls;
    for (const Item &item : std::as_const(m_items))
        knownUrls.insert(item.url);

    QList<Item> newItems;
    for (const QJsonValue &value : document.array()) {
        const QJsonObject object = value.toObject();
        const QString url = object.value("url").toString();
        if (url.isEmpty() || knownUrls.contains(url))
            continue;

        knownUrls.insert(url);
        newItems.append({
            object.value("title").toString(),
            object.value("description").toString(),
            url,
            object.value("image_url").toString(),
            object.value("thumbnail_url").toString(),
            object.value("item_count").toInt()
        });
    }

    if (newItems.isEmpty())
        return;

    const int firstRow = static_cast<int>(m_items.size());
    const int lastRow = firstRow + static_cast<int>(newItems.size()) - 1;
    beginInsertRows({}, firstRow, lastRow);
    m_items.append(newItems);
    endInsertRows();
    emit countChanged();
}

QVariantMap GalleryModel::get(int row) const {
    if (row < 0 || row >= m_items.size())
        return {};

    const Item &item = m_items[row];
    return {
        { "title", item.title },
        { "description", item.description },
        { "url", item.url },
        { "imageUrl", item.imageUrl },
        { "thumbnailUrl", item.thumbnailUrl },
        { "itemCount", item.itemCount }
    };
}
