// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import ".."

MapQuickItem {
    id: selectedSeminarCard

    property var selectedMarker: null
    property int selectedSeminarId: -1
    property var selectedSeminar: ({})

    signal openRequested(var seminar)

    visible: selectedSeminarId >= 0
    z: 160
    coordinate: selectedMarker ? selectedMarker.coordinate : QtPositioning.coordinate(0, 0)
    anchorPoint.x: card.width / 2
    anchorPoint.y: card.height + 24

    sourceItem: Rectangle {
        id: card
        width: 280
        height: 92
        radius: 10
        color: cardMouseArea.pressed
               ? Constants.pressedColor(rootWindow.isDarkMode)
               : Constants.cardBackgroundColor(rootWindow.isDarkMode)
        border.color: Constants.borderColor(rootWindow.isDarkMode)
        border.width: 2

        Rectangle {
            width: 14
            height: 14
            rotation: 45

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -7

            color: cardMouseArea.pressed
                   ? Constants.pressedColor(rootWindow.isDarkMode)
                   : Constants.cardBackgroundColor(rootWindow.isDarkMode)
            border.color: Constants.borderColor(rootWindow.isDarkMode)
            border.width: 1

            z: -1
        }

        Label {
            id: cardDate
            anchors.left: parent.left
            anchors.right: arrow.left
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            anchors.topMargin: 10

            text: (selectedSeminarCard.selectedSeminar.eventTypeLabel
                   ? selectedSeminarCard.selectedSeminar.eventTypeLabel + " \u00B7 "
                   : "") + (selectedSeminarCard.selectedSeminar.date || "")
            font.pixelSize: 12
            color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
            elide: Text.ElideRight
        }

        Label {
            id: cardTitle
            anchors.left: parent.left
            anchors.right: arrow.left
            anchors.top: cardDate.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            anchors.topMargin: 4

            text: selectedSeminarCard.selectedSeminar.title || ""
            font.pixelSize: 14
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
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            anchors.bottomMargin: 10

            text: selectedSeminarCard.selectedSeminar.city || ""
            font.pixelSize: 12
            color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
            elide: Text.ElideRight
        }

        Label {
            id: arrow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 12

            text: "\u203A"
            font.pixelSize: 26
            color: Constants.chevronColor(rootWindow.isDarkMode)
        }

        MouseArea {
            id: cardMouseArea
            anchors.fill: parent
            onClicked: selectedSeminarCard.openRequested(selectedSeminarCard.selectedSeminar)
        }
    }
}
