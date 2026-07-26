// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: dojoDetailView

    required property var mainContentStackView
    required property string titleText
    required property string streetText
    required property string zipCityText
    required property string websiteUrl
    required property string emailText
    required property string phoneText
    required property string contactText
    required property string notesText
    required property string imageUrl

    readonly property string addressText:
        [streetText, zipCityText]
            .filter(function(value) { return value !== "" })
            .join(", ")

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    header: AppToolBar {
        Item {
            anchors.fill: parent

            ToolButton {
                text: "\u2039 Zurück"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: "Dojo"
                font.bold: true
                anchors.centerIn: parent
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: dojoDetailView.width
            spacing: 14

            Rectangle {
                visible: imageUrl !== ""
                Layout.preferredWidth: 120
                Layout.preferredHeight: 120
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 22
                radius: 16
                color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: 8
                    source: imageUrl
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                }
            }

            Label {
                text: titleText
                font.pixelSize: 25
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: imageUrl === "" ? 24 : 0
            }

            InfoCard {
                title: "Adresse"
                body: [streetText, zipCityText]
                      .filter(function(value) { return value !== "" })
                      .join("\n")
                visible: body !== ""
            }

            InfoCard {
                title: "Kontakt"
                body: [
                    contactText,
                    emailText ? "E-Mail: " + emailText : "",
                    phoneText ? "Telefon: " + phoneText : ""
                ].filter(function(value) { return value !== "" }).join("\n")
                visible: body !== ""
            }

            InfoCard {
                title: "Über das Dojo"
                body: notesText
                visible: notesText !== ""
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                implicitHeight: actionColumn.implicitHeight + 28
                radius: 14
                color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
                visible: websiteUrl !== "" || emailText !== ""
                         || phoneText !== "" || addressText !== ""

                ColumnLayout {
                    id: actionColumn
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Label {
                        text: "Aktionen"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    ActionRow {
                        visible: websiteUrl !== ""
                        text: "Website öffnen"
                        onClicked: Qt.openUrlExternally(websiteUrl)
                    }

                    ActionRow {
                        visible: addressText !== ""
                        text: "In Google Maps öffnen"
                        onClicked: Qt.openUrlExternally(
                            "https://www.google.com/maps/search/?api=1&query="
                            + encodeURIComponent(addressText)
                        )
                    }

                    ActionRow {
                        visible: emailText !== ""
                        text: "E-Mail schreiben"
                        onClicked: Qt.openUrlExternally("mailto:" + emailText)
                    }

                    ActionRow {
                        visible: phoneText !== ""
                        text: "Anrufen"
                        onClicked: Qt.openUrlExternally("tel:" + phoneText)
                    }
                }
            }

            SourceAttribution {
                sourceName: "DJKB Dojo-Verzeichnis"
                sourceUrl: "https://www.djkb.com/jka-in-deutschland/djkb-dojos/"
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
            }

            Item {
                Layout.preferredHeight: 24
            }
        }
    }

    component InfoCard: Rectangle {
        property alias title: infoTitle.text
        property alias body: infoBody.text

        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        implicitHeight: infoColumn.implicitHeight + 28
        radius: 14
        color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
        border.color: Constants.borderColor(rootWindow.isDarkMode)

        ColumnLayout {
            id: infoColumn
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Label {
                id: infoTitle
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            Label {
                id: infoBody
                font.pixelSize: 14
                color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    component ActionRow: Button {
        Layout.fillWidth: true
        implicitHeight: 46
    }
}
