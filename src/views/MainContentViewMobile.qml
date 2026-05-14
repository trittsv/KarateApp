// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Layouts

import "more"
import "news"
import "seminars"

Page {
    id: mainContentView

    required property var mainContentStackView
    required property var navigationController
    property var componentCache: ({ })
    property int currentTabIndex: 0
    bottomPadding: 0

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    function pushMainContent(qmlUrl, properties = {}) {
        pushCachedView(mainContentView, mainContentStackView, qmlUrl, properties)
    }

    function pushCachedView(parentComponent, stack, qmlUrl, properties = {}) {
        if (!componentCache[qmlUrl]) {
            componentCache[qmlUrl] = Qt.createComponent(qmlUrl)
        }

        const component = componentCache[qmlUrl]

        if (component.status !== Component.Ready) {
            console.error("Failed to load:", qmlUrl, component.errorString())
            return
        }

        properties.mainContentStackView = stack

        stack.push(component, properties)
    }

    function popMainContent() {
        if (mainContentStackView.canPop()) {
            mainContentStackView.pop()
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: mainContentView.currentTabIndex

        Item {
            SeminarView {
                anchors.fill: parent
            }
        }

        Item {
            NewsView {
                anchors.fill: parent
                bottomPadding: 0
            }
        }

        Item {
            MoreView {
                anchors.fill: parent
                bottomPadding: 0
            }
        }
    }

    Item {
        id: tabBar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: Math.max(0,
                                       rootWindow.SafeArea.margins.bottom - 2)
        height: 56
        z: 100

        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: tabBar.height / 2 + 3
            color: rootWindow.isDarkMode ? "#30000000" : "#18000000"
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: rootWindow.isDarkMode ? "#F2252528" : "#F2F7F7FA"
            border.width: 1
            border.color: rootWindow.isDarkMode ? "#55FFFFFF" : "#80FFFFFF"

            MouseArea {
                anchors.fill: parent
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 3

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: mainContentView.currentTabIndex === 0
                               ? (rootWindow.isDarkMode
                                  ? "#404A4A4F" : "#20505055")
                               : "transparent"
                        border.width: mainContentView.currentTabIndex === 0
                                      ? 1 : 0
                        border.color: rootWindow.isDarkMode
                                      ? "#24FFFFFF" : "#18505055"
                    }

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 3
                        width: 18
                        height: 18
                        source: "qrc:/KarateApp/res/icons/calendar.svg"
                        color: mainContentView.currentTabIndex === 0
                               ? Constants.locationMarkerColor
                               : Constants.secondaryTextColor(
                                     rootWindow.isDarkMode)
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        text: qsTr("Termine")
                        font.pixelSize: 10
                        color: mainContentView.currentTabIndex === 0
                               ? Constants.locationMarkerColor
                               : Constants.secondaryTextColor(
                                     rootWindow.isDarkMode)
                    }

                    TapHandler {
                        onTapped: mainContentView.currentTabIndex = 0
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: mainContentView.currentTabIndex === 1
                               ? (rootWindow.isDarkMode
                                  ? "#404A4A4F" : "#20505055")
                               : "transparent"
                        border.width: mainContentView.currentTabIndex === 1
                                      ? 1 : 0
                        border.color: rootWindow.isDarkMode
                                      ? "#24FFFFFF" : "#18505055"
                    }

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 3
                        width: 18
                        height: 18
                        source: "qrc:/KarateApp/res/icons/news.svg"
                        color: mainContentView.currentTabIndex === 1
                               ? Constants.locationMarkerColor
                               : Constants.secondaryTextColor(
                                     rootWindow.isDarkMode)
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        text: qsTr("News")
                        font.pixelSize: 10
                        color: mainContentView.currentTabIndex === 1
                               ? Constants.locationMarkerColor
                               : Constants.secondaryTextColor(
                                     rootWindow.isDarkMode)
                    }

                    TapHandler {
                        onTapped: mainContentView.currentTabIndex = 1
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 1

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: mainContentView.currentTabIndex === 2
                               ? (rootWindow.isDarkMode
                                  ? "#404A4A4F" : "#20505055")
                               : "transparent"
                        border.width: mainContentView.currentTabIndex === 2
                                      ? 1 : 0
                        border.color: rootWindow.isDarkMode
                                      ? "#24FFFFFF" : "#18505055"
                    }

                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 3
                        width: 18
                        height: 18
                        source: "qrc:/KarateApp/res/icons/more.svg"
                        color: mainContentView.currentTabIndex === 2
                               ? Constants.locationMarkerColor
                               : Constants.secondaryTextColor(
                                     rootWindow.isDarkMode)
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        text: qsTr("Mehr")
                        font.pixelSize: 10
                        color: mainContentView.currentTabIndex === 2
                               ? Constants.locationMarkerColor
                               : Constants.secondaryTextColor(
                                     rootWindow.isDarkMode)
                    }

                    TapHandler {
                        onTapped: mainContentView.currentTabIndex = 2
                    }
                }
            }
        }
    }
}
