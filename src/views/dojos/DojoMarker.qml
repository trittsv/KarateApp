// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import ".."

MapQuickItem {
    id: marker

    required property int dojoId
    required property string title
    required property string street
    required property string zipCity
    required property string website
    required property string email
    required property string phone
    required property string contact
    required property string notes
    required property string imageUrl
    required property real latitude
    required property real longitude
    required property bool hasCoordinate
    property bool selected: false

    signal clicked(var markerItem)

    visible: hasCoordinate
    coordinate: QtPositioning.coordinate(latitude, longitude)
    anchorPoint.x: sourceItem.width / 2
    anchorPoint.y: sourceItem.height
    z: selected ? 150 : 90

    function dojoData() {
        return {
            dojoId: marker.dojoId,
            title: marker.title,
            street: marker.street,
            zipCity: marker.zipCity,
            website: marker.website,
            email: marker.email,
            phone: marker.phone,
            contact: marker.contact,
            notes: marker.notes,
            imageUrl: marker.imageUrl,
            latitude: marker.latitude,
            longitude: marker.longitude,
            hasCoordinate: marker.hasCoordinate
        }
    }

    sourceItem: Rectangle {
        width: marker.selected ? 40 : 34
        height: width
        radius: width / 2
        color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
        border.color: marker.selected ? Constants.accentColor : "black"
        border.width: marker.selected ? 3 : 2
        clip: true

        Image {
            id: logo
            anchors.fill: parent
            anchors.margins: 6
            source: marker.imageUrl
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: true
        }

        Label {
            anchors.centerIn: parent
            visible: logo.status !== Image.Ready
            text: marker.title.length > 0 ? marker.title.charAt(0) : "D"
            font.pixelSize: 14
            font.bold: true
            color: Constants.primaryTextColor(rootWindow.isDarkMode)
        }

        TapHandler {
            onTapped: marker.clicked(marker)
        }
    }
}
