// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <QAbstractListModel>
#include <QStringList>


struct LicenseItem {
    LicenseItem(){}
    QString name;
    QString short_text;
    QString license_text;
};

class LicenseListModel : public QAbstractListModel {

    Q_OBJECT

public:
    explicit LicenseListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    Q_INVOKABLE void download();

    QHash<int, QByteArray> roleNames() const override;
    enum roles {
        NAME = Qt::UserRole + 1,
        SHORT_TEXT,
        LICENSE_TEXT,
    };

private:
    QList<LicenseItem> m_licenses;

};
