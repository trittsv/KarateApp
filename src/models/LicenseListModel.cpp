// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "LicenseListModel.hpp"
#include "utils/Logger.hpp"


LicenseListModel::LicenseListModel(QObject *parent) : QAbstractListModel(parent) {}

int LicenseListModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) {
        return 0;
    }

    return static_cast<int>(m_licenses.size());
}

QVariant LicenseListModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid()) {
        return QVariant();
    }

    auto item = m_licenses[index.row()];

    if (role == roles::NAME) {
        return item.name;
    } else if (role == roles::SHORT_TEXT) {
        return item.short_text;
    } else if (role == roles::LICENSE_TEXT) {
        return item.license_text;
    }

    return QVariant();
}

QHash<int, QByteArray> LicenseListModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[NAME] = "name";
    roles[SHORT_TEXT] = "short_text";
    roles[LICENSE_TEXT] = "license_text";
    return roles;
}

void LicenseListModel::download() {

    LOG_DEBUG << "Setup Licenses data";

    beginResetModel();

    m_licenses.clear();

    QFile licenseFile(":/KarateApp/ThirdpartyLicenses.json");
    if(!licenseFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        LOG_DEBUG << "error: " << licenseFile.errorString();
    }

    QJsonParseError parseError;
    QJsonDocument jsonResponse = QJsonDocument::fromJson(licenseFile.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        LOG_WARN << "JsonParseError: " << parseError.errorString();
    }

    QJsonObject jsonObject = jsonResponse.object();
    QJsonArray jsonArray = jsonObject["thirdparties"].toArray();

    for (const QJsonValue &value : jsonArray) {
        LicenseItem item;
        QJsonObject obj = value.toObject();

        item.name = obj["name"].toString();

        QJsonArray jsonArrayShort = obj["short_description"].toArray();
        for (const QJsonValue &valueShort : jsonArrayShort) {
            LOG_DEBUG << valueShort;
            item.short_text += valueShort.toString() + "\n";
        }

        QJsonArray jsonArrayLicense = obj["license_text"].toArray();
        for (const QJsonValue &valueLicense : jsonArrayLicense) {
            item.license_text += valueLicense.toString() + "\n";
        }

        m_licenses.append(item);
    }

    endResetModel();
}
