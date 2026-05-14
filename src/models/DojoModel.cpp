// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "DojoModel.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>


DojoModel::DojoModel(QObject *parent)
    : QAbstractListModel(parent) {
}

int DojoModel::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : static_cast<int>(m_items.size());
}

QVariant DojoModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const DojoItem &item = m_items.at(index.row());
    switch (role) {
    case IdRole: return item.id;
    case TitleRole: return item.title;
    case StreetRole: return item.street;
    case ZipCityRole: return item.zipCity;
    case WebsiteRole: return item.website;
    case EmailRole: return item.email;
    case PhoneRole: return item.phone;
    case ContactRole: return item.contact;
    case NotesRole: return item.notes;
    case ImageUrlRole: return item.imageUrl;
    case LatitudeRole: return item.latitude;
    case LongitudeRole: return item.longitude;
    case HasCoordinateRole: return item.hasCoordinate;
    default: return {};
    }
}

QHash<int, QByteArray> DojoModel::roleNames() const {
    return {
        { IdRole, "dojoId" },
        { TitleRole, "title" },
        { StreetRole, "street" },
        { ZipCityRole, "zipCity" },
        { WebsiteRole, "website" },
        { EmailRole, "email" },
        { PhoneRole, "phone" },
        { ContactRole, "contact" },
        { NotesRole, "notes" },
        { ImageUrlRole, "imageUrl" },
        { LatitudeRole, "latitude" },
        { LongitudeRole, "longitude" },
        { HasCoordinateRole, "hasCoordinate" }
    };
}

int DojoModel::count() const {
    return static_cast<int>(m_items.size());
}

QVariantMap DojoModel::get(int row) const {
    if (row < 0 || row >= m_items.size())
        return {};

    QVariantMap item;
    const QModelIndex modelIndex = index(row);
    const auto roles = roleNames();
    for (auto role = roles.cbegin(); role != roles.cend(); ++role)
        item.insert(QString::fromUtf8(role.value()), data(modelIndex, role.key()));
    return item;
}

void DojoModel::updateCoordinate(
    int id,
    double latitude,
    double longitude
) {
    for (int row = 0; row < m_items.size(); ++row) {
        DojoItem &item = m_items[row];
        if (item.id != id)
            continue;

        item.latitude = latitude;
        item.longitude = longitude;
        item.hasCoordinate = true;
        const QModelIndex modelIndex = index(row);
        emit dataChanged(
            modelIndex,
            modelIndex,
            { LatitudeRole, LongitudeRole, HasCoordinateRole }
        );
        return;
    }
}

void DojoModel::loadFromJson(const QString &json) {
    const QJsonDocument document = QJsonDocument::fromJson(json.toUtf8());
    if (!document.isArray())
        return;

    QList<DojoItem> items;
    int id = 0;
    for (const QJsonValue &value : document.array()) {
        const QJsonObject object = value.toObject();
        const QString title = object.value("title").toString();
        if (title.isEmpty())
            continue;

        items.append({
            id++,
            title,
            object.value("street").toString(),
            object.value("zip_city").toString(),
            object.value("website").toString(),
            object.value("email").toString(),
            object.value("phone").toString(),
            object.value("contact").toString(),
            object.value("notes").toString(),
            object.value("image_url").toString(),
            object.value("latitude").toDouble(),
            object.value("longitude").toDouble(),
            object.value("has_coordinate").toBool(
                object.value("hasCoordinate").toBool()
            )
        });
    }

    beginResetModel();
    m_items = items;
    endResetModel();
    emit countChanged();
}
