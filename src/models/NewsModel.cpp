// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "NewsModel.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>


NewsModel::NewsModel(QObject *parent)
    : QAbstractListModel(parent) {
}

int NewsModel::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : static_cast<int>(m_items.size());
}

QVariant NewsModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const NewsItem &item = m_items[index.row()];

    switch (role) {
    case TitleRole: return item.title;
    case DateRole: return item.date;
    case DescriptionRole: return item.description;
    case UrlRole: return item.url;
    case ImageUrlRole: return item.imageUrl;
    case CategoryRole: return item.category;
    case ItemTypeRole: return item.itemType;
    default: return {};
    }
}

QHash<int, QByteArray> NewsModel::roleNames() const {
    return {
        { TitleRole, "title" },
        { DateRole, "date" },
        { DescriptionRole, "description" },
        { UrlRole, "url" },
        { ImageUrlRole, "imageUrl" },
        { CategoryRole, "category" },
        { ItemTypeRole, "itemType" }
    };
}

int NewsModel::count() const {
    return static_cast<int>(m_items.size());
}

void NewsModel::clear() {
    if (m_items.isEmpty())
        return;

    beginResetModel();
    m_items.clear();
    endResetModel();
    emit countChanged();
}

void NewsModel::appendFromJson(const QString &json) {
    const QJsonDocument document = QJsonDocument::fromJson(json.toUtf8());
    if (!document.isArray())
        return;

    QSet<QString> knownUrls;
    for (const NewsItem &item : std::as_const(m_items))
        knownUrls.insert(item.url);

    QList<NewsItem> newItems;
    for (const QJsonValue &value : document.array()) {
        const QJsonObject object = value.toObject();
        const QString url = object.value("url").toString();

        if (url.isEmpty() || knownUrls.contains(url))
            continue;

        knownUrls.insert(url);
        newItems.append({
            object.value("title").toString(),
            object.value("date").toString(),
            object.value("description").toString(),
            url,
            object.value("image_url").toString(),
            object.value("category").toString(),
            object.value("item_type").toString("news")
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
