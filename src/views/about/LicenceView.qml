// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: licenceView

    required property var mainContentStackView
    implicitWidth: 0
    implicitHeight: 0

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    Component.onCompleted: {
        licenseListModel.download()
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
                text: "Lizenzen Dritter"
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
        id: licenceScrollView
        anchors.fill: parent
        clip: true

        contentWidth: width
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            width: licenceScrollView.availableWidth
            spacing: 0
            topPadding: 16
            bottomPadding: 24

            ListView {
                id: licenseList
                model: licenseListModel
                width: availableWidth
                height: contentHeight
                clip: true
                interactive: false
                spacing: 12

                delegate: Item {
                    width: licenseList.width
                    height: licItemLay.implicitHeight + 28

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        radius: 14

                        color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
                        border.color: Constants.borderColor(rootWindow.isDarkMode)

                        ColumnLayout {
                            id: licItemLay
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            Label {
                                text: model.name
                                font.bold: true
                                font.pixelSize: 17
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: model.short_text
                                visible: model.short_text !== ""
                                wrapMode: Text.WordWrap
                                font.pixelSize: 13
                                opacity: 0.75
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: model.license_text !== ""
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Constants.separatorColor(rootWindow.isDarkMode)
                            }

                            Label {
                                text: model.license_text
                                visible: model.license_text !== ""
                                wrapMode: Text.WordWrap
                                font.pixelSize: 12
                                opacity: 0.7
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
