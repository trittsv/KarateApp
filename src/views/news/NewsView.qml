// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: newsView

    property string currentSection: "news"
    readonly property string sectionTitle:
        currentSection === "results" ? "Wettkampfergebnisse" : "News"

    function selectSection(section) {
        if (currentSection === section)
            return

        currentSection = section
        newsModel.clear()
        newsList.positionViewAtBeginning()
        djkbNewsScraper.loadSection(section)
    }

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    Component.onCompleted: {
        if (newsModel.count === 0 && !djkbNewsScraper.loading)
            djkbNewsScraper.loadFirstPage()
    }

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent

            Label {
                text: newsView.sectionTitle
                font.bold: true
                Layout.fillWidth: true
            }

            AppBusyIndicator {
                running: djkbNewsScraper.loading
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
            }

            ToolButton {
                id: newsMenuButton

                implicitWidth: 42
                implicitHeight: 42
                Accessible.name: "Newsbereich auswählen"
                onClicked: newsSectionMenu.open()

                contentItem: Canvas {
                    opacity: newsMenuButton.enabled ? 1 : 0.45
                    onPaint: {
                        const context = getContext("2d")
                        const lineHeight = 2.4
                        const lineWidth = width * 0.48
                        const startX = (width - lineWidth) / 2
                        const ys = [height * 0.34, height * 0.5, height * 0.66]

                        context.reset()
                        context.fillStyle = Constants.primaryTextColor(rootWindow.isDarkMode)
                        for (let i = 0; i < ys.length; ++i) {
                            context.beginPath()
                            context.roundedRect(startX, ys[i] - lineHeight / 2,
                                                lineWidth, lineHeight,
                                                lineHeight / 2, lineHeight / 2)
                            context.fill()
                        }
                    }
                }

                Menu {
                    id: newsSectionMenu

                    y: newsMenuButton.height
                    x: newsMenuButton.width - width

                    MenuItem {
                        text: "Aktuelle Meldungen"
                        checkable: true
                        checked: newsView.currentSection === "news"
                        onTriggered: newsView.selectSection("news")
                    }

                    MenuItem {
                        text: "Wettkampfergebnisse"
                        checkable: true
                        checked: newsView.currentSection === "results"
                        onTriggered: newsView.selectSection("results")
                    }
                }
            }
        }
    }

    ListView {
        id: newsList
        anchors.fill: parent
        clip: true
        model: newsModel
        spacing: 10
        topMargin: 10
        bottomMargin: rootWindow.isDesktop
                      ? 10
                      : Math.max(72, rootWindow.SafeArea.margins.bottom + 64)
        leftMargin: 10
        rightMargin: 10

        onAtYEndChanged: {
            if (atYEnd && newsModel.count > 0
                    && djkbNewsScraper.hasMore
                    && !djkbNewsScraper.loading
                    && djkbNewsScraper.errorString === "")
                djkbNewsScraper.loadMore()
        }

        delegate: ItemDelegate {
            id: newsItem

            required property string title
            required property string date
            required property string description
            required property string url
            required property string imageUrl
            required property string category
            required property string itemType

            width: newsList.width - newsList.leftMargin - newsList.rightMargin
            height: contentLayout.implicitHeight + topPadding + bottomPadding
            leftPadding: 12
            rightPadding: 12
            topPadding: 12
            bottomPadding: 12

            background: Rectangle {
                radius: 14
                color: newsItem.down
                       ? Constants.pressedColor(rootWindow.isDarkMode)
                       : Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
                border.width: 1
            }

            contentItem: RowLayout {
                id: contentLayout
                spacing: 12

                Image {
                    visible: newsItem.imageUrl !== ""
                    source: newsItem.imageUrl
                    Layout.preferredWidth: 104
                    Layout.preferredHeight: 78
                    Layout.alignment: Qt.AlignTop
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: Constants.borderColor(rootWindow.isDarkMode)
                        border.width: 1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: newsItem.date
                        font.pixelSize: 12
                        font.bold: true
                        color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
                    }

                    Label {
                        visible: newsItem.category !== ""
                        text: newsItem.category
                        font.pixelSize: 12
                        font.bold: true
                        color: Constants.accentColor
                    }

                    Label {
                        text: newsItem.title
                        font.pixelSize: 16
                        font.bold: true
                        color: Constants.primaryTextColor(rootWindow.isDarkMode)
                        Layout.fillWidth: true
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                    }

                    Label {
                        text: newsItem.description
                        font.pixelSize: 13
                        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                        Layout.fillWidth: true
                        maximumLineCount: 3
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                    }
                }

                Label {
                    text: "\u203A"
                    font.pixelSize: 26
                    color: Constants.chevronColor(rootWindow.isDarkMode)
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            onClicked: {
                if (newsItem.itemType === "result") {
                    pushMainContent(
                        "qrc:/KarateApp/src/views/seminars/SeminarPdfView.qml",
                        {
                            pdfUrl: newsItem.url,
                            titleText: newsItem.title
                        }
                    )
                } else {
                    pushMainContent(
                        "qrc:/KarateApp/src/views/news/NewsDetailView.qml",
                        {
                            articleUrl: newsItem.url,
                            titleText: newsItem.title,
                            dateText: newsItem.date,
                            descriptionText: newsItem.description,
                            imageUrl: newsItem.imageUrl
                        }
                    )
                }
            }
        }

        footer: Column {
            width: newsList.width - newsList.leftMargin - newsList.rightMargin
            spacing: 8

            Item {
                width: 1
                height: 2
            }

            Label {
                visible: djkbNewsScraper.errorString !== ""
                width: parent.width
                text: newsView.sectionTitle + " konnten nicht geladen werden."
                color: Constants.destructiveColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: djkbNewsScraper.errorString !== ""
                enabled: !djkbNewsScraper.loading
                text: "Erneut versuchen"
                onClicked: {
                    if (newsModel.count === 0)
                        djkbNewsScraper.loadFirstPage()
                    else
                        djkbNewsScraper.loadMore()
                }
            }

            AppBusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: djkbNewsScraper.loading && newsModel.count > 0
                visible: running
                width: 32
                height: 32
            }

            Label {
                visible: newsModel.count > 0 && !djkbNewsScraper.hasMore
                width: parent.width
                text: "Alle Einträge geladen"
                color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                width: 1
                height: 10
            }
        }

        Label {
            anchors.centerIn: parent
            visible: newsModel.count === 0 && !djkbNewsScraper.loading
                     && djkbNewsScraper.errorString === ""
            text: "Keine Einträge verfügbar"
            color: Constants.secondaryTextColor(rootWindow.isDarkMode)
        }
    }
}
