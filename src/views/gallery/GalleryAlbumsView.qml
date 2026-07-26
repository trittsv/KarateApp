// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: albumsView

    required property var mainContentStackView
    required property string yearTitle
    required property string yearUrl

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    Component.onCompleted: {
        galleryAlbumsModel.clear()
        djkbGalleryScraper.loadAlbums(yearUrl)
    }

    header: AppToolBar {
        Item {
            anchors.fill: parent

            ToolButton {
                text: "\u2039 Zurück"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: "Bilder " + albumsView.yearTitle
                font.bold: true
                anchors.centerIn: parent
            }

            AppBusyIndicator {
                running: djkbGalleryScraper.albumsLoading
                width: 32
                height: 32
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    ListView {
        id: albumList
        anchors.fill: parent
        clip: true
        model: galleryAlbumsModel
        spacing: 10
        topMargin: 10
        bottomMargin: 10
        leftMargin: 10
        rightMargin: 10

        delegate: ItemDelegate {
            id: albumItem

            required property string title
            required property string description
            required property string url
            required property string thumbnailUrl
            required property int itemCount

            width: albumList.width - albumList.leftMargin - albumList.rightMargin
            height: Math.max(112, contentLayout.implicitHeight + 24)
            leftPadding: 12
            rightPadding: 12
            topPadding: 12
            bottomPadding: 12

            background: Rectangle {
                radius: 14
                color: albumItem.down
                       ? Constants.pressedColor(rootWindow.isDarkMode)
                       : Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
            }

            contentItem: RowLayout {
                id: contentLayout
                spacing: 12

                Image {
                    source: albumItem.thumbnailUrl
                    Layout.preferredWidth: 112
                    Layout.preferredHeight: 84
                    Layout.alignment: Qt.AlignTop
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: albumItem.title
                        font.pixelSize: 16
                        font.bold: true
                        color: Constants.primaryTextColor(rootWindow.isDarkMode)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        visible: albumItem.description !== ""
                        text: albumItem.description
                        font.pixelSize: 13
                        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: albumItem.itemCount + " Bilder"
                        font.pixelSize: 12
                        font.bold: true
                        color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
                    }
                }

                Label {
                    text: "\u203A"
                    font.pixelSize: 26
                    color: Constants.chevronColor(rootWindow.isDarkMode)
                }
            }

            onClicked: pushMainContent(
                "qrc:/KarateApp/src/views/gallery/GalleryPhotosView.qml",
                {
                    albumTitle: albumItem.title,
                    albumUrl: albumItem.url,
                    expectedPhotoCount: albumItem.itemCount
                }
            )
        }

        footer: Column {
            width: albumList.width - albumList.leftMargin - albumList.rightMargin
            spacing: 10

            Label {
                visible: djkbGalleryScraper.albumsErrorString !== ""
                width: parent.width
                text: djkbGalleryScraper.albumsErrorString
                color: Constants.destructiveColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Button {
                visible: djkbGalleryScraper.albumsErrorString !== ""
                enabled: !djkbGalleryScraper.albumsLoading
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Erneut versuchen"
                onClicked: {
                    galleryAlbumsModel.clear()
                    djkbGalleryScraper.loadAlbums(albumsView.yearUrl)
                }
            }

            SourceAttribution {
                width: parent.width
                sourceName: "DJKB Bildergalerie " + albumsView.yearTitle
                sourceUrl: albumsView.yearUrl
            }
        }
    }
}
