// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick

Item {
    id: attribution

    property string sourceName: "Deutscher JKA-Karate Bund (DJKB)"
    property url sourceUrl: "https://www.djkb.com/"
    property bool lightText: false

    enabled: sourceUrl.toString() !== ""
    implicitWidth: sourceText.implicitWidth + 20
    implicitHeight: 38

    Accessible.role: Accessible.Link
    Accessible.name: "Quelle öffnen: " + sourceName
    Accessible.onPressAction: Qt.openUrlExternally(sourceUrl)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: tapHandler.pressed
               ? (attribution.lightText ? "#33FFFFFF" : "#12000000")
               : hoverHandler.hovered
                 ? (attribution.lightText ? "#22FFFFFF" : "#0A000000")
                 : "transparent"
    }

    Text {
        id: sourceText

        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        text: "Quelle: " + attribution.sourceName
        font.pixelSize: 12
        font.underline: true
        color: attribution.lightText
               ? "white"
               : Constants.tertiaryTextColor(rootWindow.isDarkMode)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }

    HoverHandler {
        id: hoverHandler
        enabled: attribution.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        enabled: attribution.enabled
        onTapped: Qt.openUrlExternally(attribution.sourceUrl)
    }
}
