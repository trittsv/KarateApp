// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: subscriptionView

    required property var mainContentStackView
    implicitWidth: 0
    implicitHeight: 0

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    ButtonGroup {
        id: appearanceGroup
    }

    Component.onCompleted: {
        if (rootWindow.manualAppearance) {
            systemModeRadioButton.checked = false

            if (rootWindow.isDarkMode) {
                darkModeRadioButton.checked = true
                lightModeRadioButton.checked = false
            } else {
                lightModeRadioButton.checked = true
                darkModeRadioButton.checked = false
            }
        }
    }

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent

            ToolButton {
                id: backButton
                text: "‹ Zurück"
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: "Einstellungen"
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.rightMargin: backButton.implicitWidth
            }
        }
    }

    ScrollView {
        id: settingsScrollView
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: settingsScrollView.availableWidth
            spacing: 10

            Label {
                text: "Darstellung"
                font.pixelSize: 14
                font.bold: true
                color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 18
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                implicitHeight: appearanceColumn.implicitHeight + 8
                radius: 14
                color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
                border.width: 1

                ColumnLayout {
                    id: appearanceColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    RadioButton {
                        id: systemModeRadioButton
                        text: "System"
                        checked: true
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 54

                        onClicked: {
                            if (checked) {
                                rootWindow.manualAppearance = false
                                ClipboardHelper.setColorScheme(0)
                            }
                        }

                        ButtonGroup.group: appearanceGroup
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.preferredHeight: 1
                        color: Constants.separatorColor(rootWindow.isDarkMode)
                    }

                    RadioButton {
                        id: darkModeRadioButton
                        text: "Dunkel"
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 54

                        onClicked: {
                            rootWindow.manualAppearance = true

                            if (checked)
                                ClipboardHelper.setColorScheme(2)
                        }

                        ButtonGroup.group: appearanceGroup
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.preferredHeight: 1
                        color: Constants.separatorColor(rootWindow.isDarkMode)
                    }

                    RadioButton {
                        id: lightModeRadioButton
                        text: "Hell"
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 54

                        onClicked: {
                            rootWindow.manualAppearance = true

                            if (checked)
                                ClipboardHelper.setColorScheme(1)
                        }

                        ButtonGroup.group: appearanceGroup
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
            }
        }
    }
}
