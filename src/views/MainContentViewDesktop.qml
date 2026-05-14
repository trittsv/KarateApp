// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "more"
import "news"
import "seminars"

Page {
    id: mainContentView

    required property var mainContentStackView
    required property var navigationController
    property var componentCache: ({})

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    function pushMainContent(qmlUrl, properties = {}) {
        pushCachedView(mainContentView, mainContentStackView, qmlUrl, properties)
    }

    function pushCachedView(parentComponent, stack, qmlUrl, properties = {}) {
        if (!componentCache[qmlUrl])
            componentCache[qmlUrl] = Qt.createComponent(qmlUrl)

        const component = componentCache[qmlUrl]

        if (component.status !== Component.Ready) {
            console.error("Failed to load:", qmlUrl, component.errorString())
            return
        }

        properties.mainContentStackView = stack
        stack.push(component, properties)
    }

    function popMainContent() {
        if (mainContentStackView.canPop())
            mainContentStackView.pop()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            color: Constants.safeEdgeColor(rootWindow.isDarkMode)
            border.color: Constants.borderColor(rootWindow.isDarkMode)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Label {
                    text: "Karate App"
                    font.pixelSize: 20
                    font.bold: true
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 8
                }

                Button {
                    text: qsTr("Termine")
                    icon.source: "qrc:/KarateApp/res/icons/calendar.svg"
                    display: AbstractButton.TextBesideIcon
                    checkable: true
                    checked: contentTabs.currentIndex === 0
                    Layout.fillWidth: true
                    onClicked: {
                        mainContentView.popMainContent()
                        contentTabs.currentIndex = 0
                    }
                }

                Button {
                    text: qsTr("News")
                    icon.source: "qrc:/KarateApp/res/icons/news.svg"
                    display: AbstractButton.TextBesideIcon
                    checkable: true
                    checked: contentTabs.currentIndex === 1
                    Layout.fillWidth: true
                    onClicked: {
                        mainContentView.popMainContent()
                        contentTabs.currentIndex = 1
                    }
                }

                Button {
                    text: qsTr("Mehr")
                    icon.source: "qrc:/KarateApp/res/icons/more.svg"
                    display: AbstractButton.TextBesideIcon
                    checkable: true
                    checked: contentTabs.currentIndex === 2
                    Layout.fillWidth: true
                    onClicked: {
                        mainContentView.popMainContent()
                        contentTabs.currentIndex = 2
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StackLayout {
                id: contentTabs
                anchors.fill: parent

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    SeminarView {
                        anchors.fill: parent
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    NewsView {
                        anchors.fill: parent
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    MoreView {
                        anchors.fill: parent
                    }
                }
            }
        }
    }
}
