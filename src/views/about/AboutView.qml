// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: aboutView

    required property var mainContentStackView
    property bool showBackButton: false

    implicitWidth: 0
    implicitHeight: 0

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    header: AppToolBar {
        Item {
            anchors.fill: parent

            ToolButton {
                visible: aboutView.showBackButton
                text: "\u2039 Zurück"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: "Über"
                font.bold: true
                anchors.centerIn: parent
            }
        }
    }

    ScrollView {
        id: aboutScrollView
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        contentWidth: width

        ColumnLayout {
            width: aboutScrollView.availableWidth
            spacing: 12

            Item {
                Layout.preferredHeight: 5
                Layout.fillWidth: true
            }

            AboutTile {
                text: "Impressum"
                onClicked: pushMainContent("qrc:/KarateApp/src/views/about/Imprint.qml")
            }

            AboutTile {
                text: "Einstellungen"
                onClicked: pushMainContent("qrc:/KarateApp/src/views/about/SettingsView.qml")
            }

            AboutTile {
                text: "Lizenzen Dritter"
                onClicked: pushMainContent("qrc:/KarateApp/src/views/about/LicenceView.qml")
            }

            AboutTile {
                text: "App-Informationen"
                onClicked: pushMainContent(
                    "qrc:/KarateApp/src/views/about/AppInfoView.qml"
                )
            }

            Item {
                Layout.preferredHeight: 12
                Layout.fillWidth: true
            }
        }

    }

    component AboutTile: Rectangle {
        id: tile

        signal clicked()
        property alias text: titleLabel.text
        property bool pressed: false

        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        height: 64
        radius: 14

        color: pressed
               ? Constants.pressedColor(rootWindow.isDarkMode)
               : Constants.cardBackgroundColor(rootWindow.isDarkMode)

        border.color: Constants.borderColor(rootWindow.isDarkMode)

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16

            Label {
                id: titleLabel
                font.pixelSize: 16
                Layout.fillWidth: true
            }

            Label {
                text: "›"
                font.pixelSize: 24
                color: Constants.chevronColor(rootWindow.isDarkMode)
            }
        }

        MouseArea {
            anchors.fill: parent

            onPressed: tile.pressed = true
            onReleased: tile.pressed = false
            onCanceled: tile.pressed = false

            onClicked: tile.clicked()
        }
    }
}
