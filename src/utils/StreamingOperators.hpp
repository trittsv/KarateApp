// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#pragma once

#include <sstream>

#include <QFileInfo>
#include <QUrl>
#include <QJsonArray>
#include <QDateTime>
#include <QJsonValue>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMutex>
#include <QString>


inline std::ostream& operator<<(std::ostream& os, const QString& str) {
    os << str.toStdString();
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const QByteArray& byteArray) {
    os.write(byteArray.data(), byteArray.size());
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const QUrl& url) {
    os << url.toString().toStdString();
    return os;
}


inline std::ostream& operator<<(std::ostream& os, const QDateTime& dateTime) {
    os << dateTime.toString(Qt::ISODate).toStdString(); // Convert to ISO 8601 format
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const QJsonValue& value) {
    switch (value.type()) {
    case QJsonValue::String:
        os << '"' << value.toString().toStdString() << '"';
        break;
    case QJsonValue::Double:
        os << value.toDouble();
        break;
    case QJsonValue::Bool:
        os << (value.toBool() ? "true" : "false");
        break;
    case QJsonValue::Object:
        os << QJsonDocument(value.toObject()).toJson(QJsonDocument::Compact).toStdString();
        break;
    case QJsonValue::Array:
        os << QJsonDocument(value.toArray()).toJson(QJsonDocument::Compact).toStdString();
        break;
    case QJsonValue::Null:
        os << "null";
        break;
    default:
        os << "unknown";
        break;
    }
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const QJsonArray& jsonArray) {
    os << "[";
    for (int i = 0; i < jsonArray.size(); ++i) {
        if (i > 0) {
            os << ", ";
        }
        const QJsonValue& value = jsonArray[i];
        os << value;
    }
    os << "]";
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const QJsonDocument& jsonDoc) {
    QString jsonString = jsonDoc.toJson(QJsonDocument::Compact);
    os << jsonString.toStdString();
    return os;
}

template <typename T>
inline std::ostream& operator<<(std::ostream& os, const QList<T>& list) {
    os << "[";
    for (int i = 0; i < list.size(); ++i) {
        if (i > 0) {
            os << ", ";
        }
        os << list[i];
    }
    os << "]";
    return os;
}

inline QByteArray dataStreamToByteArray(QDataStream& stream) {
    QByteArray byteArray;
    qint32 size;
    stream >> size;
    byteArray.resize(size);
    stream.readRawData(byteArray.data(), size);
    return byteArray;
}

inline std::ostream& operator<<(std::ostream& os, QDataStream& dataStream) {
    QByteArray byteArray = dataStreamToByteArray(dataStream);
    os.write(byteArray.data(), byteArray.size());
    return os;
}
