// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: legalView

    required property var mainContentStackView

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    header: AppToolBar {
        Item {
            anchors.fill: parent

            ToolButton {
                id: backButton
                text: "\u2039 Zurück"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: "Rechtliches und Datenschutz"
                font.bold: true
                anchors.centerIn: parent
                width: parent.width - 2 * backButton.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }

    ScrollView {
        id: legalScrollView

        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: legalScrollView.availableWidth
            spacing: 10

            LegalTile {
                Layout.topMargin: 16
                title: "Datenschutz"
                description: "Umgang mit Daten und Standort"
                onClicked: Qt.openUrlExternally(
                    "https://karate-api.ddns.net/privacy"
                )
            }

            LegalTile {
                title: "Impressum"
                description: "Anbieter- und Kontaktangaben"
                onClicked: Qt.openUrlExternally(
                    "https://karate-api.ddns.net/imprint"
                )
            }

            LegalTile {
                title: "Lizenzen Dritter"
                description: "Verwendete Open-Source-Komponenten"
                onClicked: pushMainContent(
                    "qrc:/KarateApp/src/views/about/LicenceView.qml"
                )
            }

            LegalTile {
                title: "App-Informationen"
                description: "Version, Build und Systemdetails"
                Layout.bottomMargin: 16
                onClicked: pushMainContent(
                    "qrc:/KarateApp/src/views/about/AppInfoView.qml"
                )
            }
        }
    }

    component LegalTile: ItemDelegate {
        id: tile

        required property string title
        required property string description

        implicitHeight: 72
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        leftPadding: 16
        rightPadding: 16

        background: Rectangle {
            radius: 14
            color: tile.down
                   ? Constants.pressedColor(rootWindow.isDarkMode)
                   : Constants.cardBackgroundColor(rootWindow.isDarkMode)
            border.color: Constants.borderColor(rootWindow.isDarkMode)
            border.width: 1
        }

        contentItem: RowLayout {
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Label {
                    text: tile.title
                    font.pixelSize: 16
                    font.bold: true
                    color: Constants.primaryTextColor(rootWindow.isDarkMode)
                    Layout.fillWidth: true
                }

                Label {
                    text: tile.description
                    font.pixelSize: 13
                    color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Label {
                text: "\u203A"
                font.pixelSize: 26
                color: Constants.chevronColor(rootWindow.isDarkMode)
            }
        }
    }
}
