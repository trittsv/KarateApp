// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: yearsView

    required property var mainContentStackView
    property bool showBackButton: false

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    Component.onCompleted: {
        if (galleryYearsModel.count === 0 && !djkbGalleryScraper.yearsLoading)
            djkbGalleryScraper.loadYears()
    }

    header: AppToolBar {
        Item {
            anchors.fill: parent

            ToolButton {
                visible: yearsView.showBackButton
                text: "\u2039 Zurück"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: "Bilder"
                font.bold: true
                anchors.centerIn: parent
            }

            AppBusyIndicator {
                running: djkbGalleryScraper.yearsLoading
                width: 32
                height: 32
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    ListView {
        id: yearList
        anchors.fill: parent
        clip: true
        model: galleryYearsModel
        spacing: 10
        topMargin: 10
        bottomMargin: 10
        leftMargin: 10
        rightMargin: 10

        delegate: ItemDelegate {
            id: yearItem

            required property string title
            required property string url

            width: yearList.width - yearList.leftMargin - yearList.rightMargin
            height: 68
            leftPadding: 16
            rightPadding: 16

            background: Rectangle {
                radius: 14
                color: yearItem.down
                       ? Constants.pressedColor(rootWindow.isDarkMode)
                       : Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
            }

            contentItem: RowLayout {
                Label {
                    text: yearItem.title
                    font.pixelSize: 19
                    font.bold: true
                    color: Constants.primaryTextColor(rootWindow.isDarkMode)
                    Layout.fillWidth: true
                }

                Label {
                    text: "\u203A"
                    font.pixelSize: 26
                    color: Constants.chevronColor(rootWindow.isDarkMode)
                }
            }

            onClicked: pushMainContent(
                "qrc:/KarateApp/src/views/gallery/GalleryAlbumsView.qml",
                {
                    yearTitle: yearItem.title,
                    yearUrl: yearItem.url
                }
            )
        }

        footer: Column {
            width: yearList.width - yearList.leftMargin - yearList.rightMargin
            spacing: 10

            Label {
                visible: djkbGalleryScraper.yearsErrorString !== ""
                width: parent.width
                text: "Die Bilder-Jahrgänge konnten nicht geladen werden."
                color: Constants.destructiveColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Button {
                visible: djkbGalleryScraper.yearsErrorString !== ""
                enabled: !djkbGalleryScraper.yearsLoading
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Erneut versuchen"
                onClicked: djkbGalleryScraper.loadYears()
            }

            SourceAttribution {
                width: parent.width
                sourceName: "DJKB Bildergalerie"
                sourceUrl: galleryYearsModel.count > 0
                           ? galleryYearsModel.get(0).url
                           : "https://www.djkb.com/bilder/"
                             + new Date().getFullYear() + "/"
            }
        }
    }
}
