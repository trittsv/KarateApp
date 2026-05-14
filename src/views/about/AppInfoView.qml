// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: appInfoView

    required property var mainContentStackView
    implicitWidth: 0
    implicitHeight: 0

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent

            ToolButton {
                id: backButton
                text: "\u2039 Zurück"
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: "App-Informationen"
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
        id: appInfoScrollView
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: appInfoScrollView.availableWidth
            spacing: 12

            InfoCard {
                Layout.topMargin: 16
                title: "App"

                InfoRow {
                    title: "Version"
                    value: KARATEAPP_VERSION
                }

                InfoRow {
                    title: "Build-Datum"
                    value: KARATEAPP_BUILD_DATE
                }

                InfoRow {
                    title: "Git-Commit"
                    value: KARATEAPP_GIT_COMMIT
                }

                InfoRow {
                    title: "Qt-Version"
                    value: KARATEAPP_QT_VERSION
                }
            }

            InfoCard {
                title: "Betriebssystem"

                InfoRow {
                    title: "Produkt"
                    value: KARATEAPP_SYSTEM_INFO.prettyProductName
                }

                InfoRow {
                    title: "Produkttyp"
                    value: KARATEAPP_SYSTEM_INFO.productType
                }

                InfoRow {
                    title: "Produktversion"
                    value: KARATEAPP_SYSTEM_INFO.productVersion
                }

                InfoRow {
                    title: "Kernel"
                    value: KARATEAPP_SYSTEM_INFO.kernelType
                }

                InfoRow {
                    title: "Kernel-Version"
                    value: KARATEAPP_SYSTEM_INFO.kernelVersion
                }
            }

            InfoCard {
                title: "Hardware"

                InfoRow {
                    title: "Build-CPU"
                    value: KARATEAPP_SYSTEM_INFO.buildCpuArchitecture
                }

                InfoRow {
                    title: "Aktuelle CPU"
                    value: KARATEAPP_SYSTEM_INFO.currentCpuArchitecture
                }

                InfoRow {
                    title: "Build-ABI"
                    value: KARATEAPP_SYSTEM_INFO.buildAbi
                }
            }

            InfoCard {
                title: "Geräteinformationen"

                InfoRow {
                    title: "Hostname"
                    value: KARATEAPP_SYSTEM_INFO.machineHostName
                }

                InfoRow {
                    title: "Boot-ID"
                    value: KARATEAPP_SYSTEM_INFO.bootUniqueId
                }

                InfoRow {
                    title: "Geräte-ID"
                    value: KARATEAPP_SYSTEM_INFO.machineUniqueId
                }
            }

            Item {
                Layout.preferredHeight: 12
                Layout.fillWidth: true
            }
        }
    }

    component InfoCard: Rectangle {
        id: infoCard

        required property string title
        default property alias content: cardLayout.data

        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        implicitHeight: cardLayout.implicitHeight + 32
        radius: 14
        color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
        border.color: Constants.borderColor(rootWindow.isDarkMode)
        border.width: 1

        ColumnLayout {
            id: cardLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Label {
                text: infoCard.title
                font.pixelSize: 16
                font.bold: true
                color: Constants.primaryTextColor(rootWindow.isDarkMode)
                Layout.fillWidth: true
            }
        }
    }

    component InfoRow: RowLayout {
        id: infoRow

        required property string title
        required property string value

        Layout.fillWidth: true
        spacing: 12

        Label {
            text: infoRow.title
            font.pixelSize: 14
            color: Constants.secondaryTextColor(rootWindow.isDarkMode)
            Layout.preferredWidth: 120
            Layout.alignment: Qt.AlignTop
        }

        Label {
            text: infoRow.value
            font.pixelSize: 14
            color: Constants.primaryTextColor(rootWindow.isDarkMode)
            wrapMode: Text.WrapAnywhere
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignRight
            Layout.fillWidth: true
        }
    }
}
