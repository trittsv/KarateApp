// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: moreView

    implicitWidth: 0
    implicitHeight: 0

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent

            Label {
                text: "Mehr"
                font.bold: true
                Layout.fillWidth: true
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: moreView.width
            spacing: 10

            Item {
                Layout.preferredHeight: 2
            }

            SectionLabel {
                text: "Weitere Inhalte"
            }

            NavigationTile {
                title: "Dojos"
                description: "DJKB-Vereine nach Name, PLZ oder Ort finden"
                iconSource: "qrc:/KarateApp/res/icons/dojo.svg"
                onClicked: {
                    if (dojoModel.count === 0 && !backendApiClient.dojoLoading)
                        backendApiClient.loadDojos()

                    pushMainContent(
                        "qrc:/KarateApp/src/views/dojos/DojoView.qml",
                        { showBackButton: true }
                    )
                }
            }

            NavigationTile {
                title: "Bilder"
                description: "DJKB-Fotoalben nach Jahr durchsuchen"
                iconSource: "qrc:/KarateApp/res/icons/gallery.svg"
                onClicked: pushMainContent(
                    "qrc:/KarateApp/src/views/gallery/GalleryYearsView.qml",
                    { showBackButton: true }
                )
            }

            SectionLabel {
                text: "Einstellungen"
                Layout.topMargin: 8
            }

            NavigationTile {
                title: "Einstellungen"
                description: "Darstellung und Verhalten anpassen"
                iconSource: "qrc:/KarateApp/res/icons/more.svg"
                onClicked: pushMainContent(
                    "qrc:/KarateApp/src/views/about/SettingsView.qml"
                )
            }

            SectionLabel {
                text: "Hilfe und Feedback"
                Layout.topMargin: 8
            }

            NavigationTile {
                title: "Feedback"
                description: "Ideen, Fehler oder Hinweise per E-Mail senden"
                iconSource: "qrc:/KarateApp/res/icons/feedback.svg"
                onClicked: Qt.openUrlExternally(
                    "mailto:karateapp@gmx.de?subject=Feedback%20zur%20Karate%20App"
                )
            }

            NavigationTile {
                title: "App bewerten"
                description: Qt.platform.os === "android"
                             ? "Bei Google Play bewerten"
                             : "Im App Store bewerten"
                iconSource: "qrc:/KarateApp/res/icons/rating.svg"
                visible: Qt.platform.os === "android"
                         || (Qt.platform.os === "ios"
                             && KARATEAPP_APP_STORE_ID !== "")
                onClicked: {
                    if (Qt.platform.os === "android") {
                        Qt.openUrlExternally(
                            "https://play.google.com/store/apps/details"
                            + "?id=" + KARATEAPP_GOOGLE_PLAY_APP_ID
                            + "&showAllReviews=true"
                        )
                    } else if (Qt.platform.os === "ios") {
                        Qt.openUrlExternally(
                            "https://apps.apple.com/app/id"
                            + KARATEAPP_APP_STORE_ID
                            + "?action=write-review"
                        )
                    }
                }
            }

            NavigationTile {
                title: "Rechtliches und Datenschutz"
                description: "Datenschutz, Impressum und Lizenzen"
                iconSource: "qrc:/KarateApp/res/icons/info.svg"
                onClicked: pushMainContent(
                    "qrc:/KarateApp/src/views/about/LegalView.qml"
                )
            }

            Label {
                text: "Made with ❤️ OSS!\nVersion " + KARATEAPP_VERSION
                opacity: 0.5
                font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 14
            }
        }
    }

    component SectionLabel: Label {
        font.pixelSize: 13
        font.bold: true
        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
        Layout.fillWidth: true
        Layout.leftMargin: 18
        Layout.rightMargin: 18
    }

    component NavigationTile: ItemDelegate {
        id: tile

        property alias title: titleLabel.text
        property alias description: descriptionLabel.text
        property url iconSource

        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        implicitHeight: 82
        leftPadding: 14
        rightPadding: 14

        background: Rectangle {
            radius: 14
            color: tile.down
                   ? Constants.pressedColor(rootWindow.isDarkMode)
                   : Constants.cardBackgroundColor(rootWindow.isDarkMode)
            border.color: Constants.borderColor(rootWindow.isDarkMode)
            border.width: 1
        }

        contentItem: RowLayout {
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 12
                color: Constants.secondaryCardBackgroundColor(rootWindow.isDarkMode)

                ToolButton {
                    anchors.fill: parent
                    enabled: false
                    opacity: 1
                    display: AbstractButton.IconOnly
                    icon.source: tile.iconSource
                    icon.width: 28
                    icon.height: 28
                    icon.color: Constants.primaryTextColor(rootWindow.isDarkMode)

                    background: Item {}
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Label {
                    id: titleLabel
                    font.pixelSize: 17
                    font.bold: true
                    color: Constants.primaryTextColor(rootWindow.isDarkMode)
                    Layout.fillWidth: true
                }

                Label {
                    id: descriptionLabel
                    font.pixelSize: 13
                    color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                    wrapMode: Text.WordWrap
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
