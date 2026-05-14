// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

#include "SeminarModel.hpp"

#include <QJsonDocument>
#include <QJsonValue>
#include <QRegularExpression>
#include <algorithm>
#include <cmath>

SeminarModel::SeminarModel(QObject *parent)
    : QAbstractListModel(parent) {
}

int SeminarModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid())
        return 0;

    return static_cast<int>(m_items.size());
}

int SeminarModel::count() const {
    return static_cast<int>(m_items.size());
}

QVariant SeminarModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const Seminar &s = m_items[index.row()];

    switch (role) {
    case IdRole: return s.id;
    case AppointmentIdRole: return s.appointmentId;
    case TitleRole: return s.title;
    case DateRole: return s.date;
    case CategoryRole: return s.category;
    case EventTypeRole: return s.eventType;
    case EventTypeLabelRole: return eventTypeLabel(s.eventType);
    case DojoRole: return s.dojo;
    case ContactRole: return s.contact;
    case EmailRole: return s.email;
    case PhoneRole: return s.phone;
    case PdfUrlRole: return s.pdfUrl;
    case IcsUrlRole: return s.icsUrl;
    case StreetRole: return s.street;
    case ZipRole: return s.zip;
    case CityRole: return s.city;
    case CountryRole: return s.country;
    case MapsUrlRole: return s.mapsUrl;
    case LatitudeRole: return s.latitude;
    case LongitudeRole: return s.longitude;
    case HasCoordinateRole: return s.hasCoordinate;
    case DistanceKmRole: return s.distanceKm;
    case DistanceTextRole: return distanceText(s);
    case DateSortValueRole: return parseGermanDate(s.date).toString(Qt::ISODate);
    case IsOutdatedRole: return isOutdated(s.date);
    default: return {};
    }
}

QHash<int, QByteArray> SeminarModel::roleNames() const {
    return {
        { IdRole, "seminarId" },
        { AppointmentIdRole, "appointmentId" },
        { TitleRole, "title" },
        { DateRole, "date" },
        { CategoryRole, "category" },
        { EventTypeRole, "eventType" },
        { EventTypeLabelRole, "eventTypeLabel" },
        { DojoRole, "dojo" },
        { ContactRole, "contact" },
        { EmailRole, "email" },
        { PhoneRole, "phone" },
        { PdfUrlRole, "pdf_url" },
        { IcsUrlRole, "ics_url" },
        { StreetRole, "street" },
        { ZipRole, "zip" },
        { CityRole, "city" },
        { CountryRole, "country" },
        { MapsUrlRole, "maps_url" },
        { LatitudeRole, "latitude" },
        { LongitudeRole, "longitude" },
        { HasCoordinateRole, "hasCoordinate" },
        { DistanceKmRole, "distanceKm" },
        { DistanceTextRole, "distanceText" },
        { DateSortValueRole, "dateSortValue" },
        { IsOutdatedRole, "isOutdated" }
    };
}

QVariantMap SeminarModel::get(int row) const {
    QVariantMap m;

    if (row < 0 || row >= m_items.size())
        return m;

    const Seminar &s = m_items[row];

    m["seminarId"] = s.id;
    m["appointmentId"] = s.appointmentId;
    m["title"] = s.title;
    m["date"] = s.date;
    m["category"] = s.category;
    m["eventType"] = s.eventType;
    m["eventTypeLabel"] = eventTypeLabel(s.eventType);
    m["dojo"] = s.dojo;
    m["contact"] = s.contact;
    m["email"] = s.email;
    m["phone"] = s.phone;
    m["pdf_url"] = s.pdfUrl;
    m["ics_url"] = s.icsUrl;

    m["street"] = s.street;
    m["zip"] = s.zip;
    m["city"] = s.city;
    m["country"] = s.country;
    m["maps_url"] = s.mapsUrl;

    m["latitude"] = s.latitude;
    m["longitude"] = s.longitude;
    m["hasCoordinate"] = s.hasCoordinate;
    m["distanceText"] = distanceText(s);
    m["isOutdated"] = isOutdated(s.date);

    return m;
}

void SeminarModel::loadFromJson(const QString &json) {
    const QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());

    if (!doc.isArray())
        return;

    beginResetModel();

    m_items.clear();
    m_nextId = 1;

    const QJsonArray array = doc.array();

    for (const QJsonValue &value : array) {
        const QJsonObject o = value.toObject();
        const QJsonObject loc = o.value("location").toObject();

        Seminar s;
        s.id = m_nextId++;
        s.appointmentId = o.value("appointment_id").toString();

        s.title = o.value("title").toString();
        s.date = o.value("date").toString();
        s.category = o.value("category").toString();
        s.eventType = o.value("event_type").toString("seminar");
        s.dojo = o.value("dojo").toString();
        s.contact = o.value("contact").toString();
        s.email = o.value("email").toString();
        s.phone = o.value("phone").toString();
        s.pdfUrl = o.value("pdf_url").toString();
        s.icsUrl = o.value("ics_url").toString();

        s.street = loc.value("street").toString();
        s.zip = loc.value("zip").toString();
        s.city = loc.value("city").toString();
        s.country = loc.value("country").toString("Germany");
        s.mapsUrl = loc.value("maps_url").toString();
        s.latitude = loc.value("latitude").toDouble();
        s.longitude = loc.value("longitude").toDouble();
        s.hasCoordinate = loc.value("has_coordinate").toBool(
            loc.value("hasCoordinate").toBool()
        );
        updateDistance(s);

        m_items.append(s);
    }

    endResetModel();
    emit countChanged();
}

void SeminarModel::updateCoordinate(int id, double latitude, double longitude) {
    const QGeoCoordinate coordinate(latitude, longitude);
    if (!coordinate.isValid()
            || (qFuzzyIsNull(latitude) && qFuzzyIsNull(longitude)))
        return;

    const int row = rowById(id);
    if (row < 0)
        return;

    Seminar &s = m_items[row];

    s.latitude = latitude;
    s.longitude = longitude;
    s.hasCoordinate = true;
    updateDistance(s);

    emit dataChanged(index(0), index(static_cast<int>(m_items.size()) - 1));
}

void SeminarModel::updateUserPosition(double latitude, double longitude) {
    m_userCoordinate = QGeoCoordinate(latitude, longitude);
    m_hasUserCoordinate = true;

    for (Seminar &s : m_items) {
        updateDistance(s);
    }

    if (!m_items.isEmpty())
        emit dataChanged(index(0), index(static_cast<int>(m_items.size()) - 1));
}

QDate SeminarModel::parseGermanDate(const QString &date) {
    static const QRegularExpression dateExpression(
        QStringLiteral(R"((\d{1,2})\.(\d{1,2})\.(\d{2,4}))")
    );

    const QRegularExpressionMatch match = dateExpression.match(date);
    if (!match.hasMatch())
        return {};

    QString year = match.captured(3);
    if (year.size() == 2)
        year.prepend(QStringLiteral("20"));

    return QDate(
        year.toInt(),
        match.captured(2).toInt(),
        match.captured(1).toInt()
    );
}

QDate SeminarModel::parseGermanEndDate(const QString &date) {
    static const QRegularExpression dateExpression(
        QStringLiteral(R"((\d{1,2})\.(\d{1,2})\.(\d{2,4}))")
    );

    QDate endDate;
    QRegularExpressionMatchIterator matches = dateExpression.globalMatch(date);

    while (matches.hasNext()) {
        const QRegularExpressionMatch match = matches.next();
        QString year = match.captured(3);
        if (year.size() == 2)
            year.prepend(QStringLiteral("20"));

        const QDate parsedDate(
            year.toInt(),
            match.captured(2).toInt(),
            match.captured(1).toInt()
        );

        if (parsedDate.isValid())
            endDate = parsedDate;
    }

    return endDate;
}

bool SeminarModel::isOutdated(const QString &date) {
    const QDate endDate = parseGermanEndDate(date);
    return endDate.isValid() && endDate < QDate::currentDate();
}

QString SeminarModel::eventTypeLabel(const QString &eventType) {
    if (eventType == "competition")
        return "Wettkampf";

    if (eventType == "national_team")
        return "Bundeskader";

    if (eventType == "regional_team")
        return "Stützpunktkader";

    if (eventType == "training")
        return "Ausbildung";

    return "Lehrgang";
}

QString SeminarModel::distanceText(const Seminar &s) const {
    if (!s.hasCoordinate
            || s.distanceKm < 0.0
            || !std::isfinite(s.distanceKm))
        return "";

    return QString::number(s.distanceKm, 'f', 1) + " km";
}

void SeminarModel::updateDistance(Seminar &s) {
    if (!m_hasUserCoordinate || !s.hasCoordinate) {
        s.distanceKm = -1.0;
        return;
    }

    const QGeoCoordinate target(s.latitude, s.longitude);
    if (!target.isValid()) {
        s.distanceKm = -1.0;
        return;
    }

    s.distanceKm = m_userCoordinate.distanceTo(target) / 1000.0;
}

void SeminarModel::sortItems() {
    std::sort(m_items.begin(), m_items.end(), [](const Seminar &a, const Seminar &b) {
        const bool aHasDistance = a.distanceKm >= 0.0;
        const bool bHasDistance = b.distanceKm >= 0.0;

        if (aHasDistance && bHasDistance && !qFuzzyCompare(a.distanceKm, b.distanceKm))
            return a.distanceKm < b.distanceKm;

        if (aHasDistance != bHasDistance)
            return aHasDistance;

        return parseGermanDate(a.date) < parseGermanDate(b.date);
    });
}

int SeminarModel::rowById(int id) const {
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items[i].id == id)
            return i;
    }

    return -1;
}

Q_INVOKABLE QVariantMap SeminarModel::getById(int seminarId) const
{
    for (int i = 0; i < m_items.size(); ++i) {
        if (m_items[i].id == seminarId)
            return get(i);
    }

    return {};
}
