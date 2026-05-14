// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import ".."

MapQuickItem {
    id: dojoCard

    property var dojo: ({})
    signal openRequested(var dojo)

    visible: dojo && dojo.hasCoordinate === true
    coordinate: visible
                ? QtPositioning.coordinate(dojo.latitude, dojo.longitude)
                : QtPositioning.coordinate(0, 0)
    anchorPoint.x: card.width / 2
    anchorPoint.y: card.height + 28
    z: 160

    sourceItem: Rectangle {
        id: card

        width: 286
        height: 94
        radius: 12
        color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
        border.color: Constants.borderColor(rootWindow.isDarkMode)
        border.width: 2

        Rectangle {
            width: 14
            height: 14
            rotation: 45
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -7
            color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
            border.color: Constants.borderColor(rootWindow.isDarkMode)
            z: -1
        }

        Label {
            anchors.left: parent.left
            anchors.right: arrow.left
            anchors.top: parent.top
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            anchors.topMargin: 12
            text: dojoCard.dojo.title || ""
            font.pixelSize: 15
            font.bold: true
            color: Constants.primaryTextColor(rootWindow.isDarkMode)
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
        }

        Label {
            anchors.left: parent.left
            anchors.right: arrow.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            anchors.bottomMargin: 11
            text: dojoCard.dojo.zipCity || dojoCard.dojo.street || ""
            font.pixelSize: 12
            color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
            elide: Text.ElideRight
        }

        Label {
            id: arrow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 13
            text: "\u203A"
            font.pixelSize: 26
            color: Constants.chevronColor(rootWindow.isDarkMode)
        }

        TapHandler {
            onTapped: dojoCard.openRequested(dojoCard.dojo)
        }
    }
}
