// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: newsDetailView

    required property var mainContentStackView
    required property string articleUrl
    required property string titleText
    required property string dateText
    required property string descriptionText
    required property string imageUrl

    property string bodyText: descriptionText
    property var imageUrls: imageUrl !== "" ? [imageUrl] : []

    function openImageViewer() {
        fullScreenGallery.reset()
        imageViewer.open()
    }

    Component.onCompleted: djkbNewsScraper.loadDetail(articleUrl)

    Connections {
        target: djkbNewsScraper

        function onDetailLoaded(url, detailJson) {
            if (url !== newsDetailView.articleUrl)
                return

            const detail = JSON.parse(detailJson)
            newsDetailView.titleText = detail.title || newsDetailView.titleText
            newsDetailView.dateText = detail.date || newsDetailView.dateText
            newsDetailView.bodyText = detail.body || newsDetailView.descriptionText
            newsDetailView.imageUrls = detail.images && detail.images.length > 0
                                       ? detail.images
                                       : (newsDetailView.imageUrl !== ""
                                          ? [newsDetailView.imageUrl]
                                          : [])
        }
    }

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
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
                text: "News"
                font.bold: true
                anchors.centerIn: parent
            }

            ToolButton {
                text: "Teilen"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: ClipboardHelper.shareUrl(newsDetailView.articleUrl)
            }
        }
    }

    ScrollView {
        id: detailScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: detailScroll.availableWidth
            spacing: 12

            Rectangle {
                id: articleCard
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 12
                implicitHeight: articleColumn.implicitHeight + 32
                radius: 14
                color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
                border.width: 1

                ColumnLayout {
                    id: articleColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Label {
                        text: newsDetailView.dateText
                        font.pixelSize: 13
                        font.bold: true
                        color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
                    }

                    Label {
                        text: newsDetailView.titleText
                        font.pixelSize: 26
                        font.bold: true
                        color: Constants.primaryTextColor(rootWindow.isDarkMode)
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: newsDetailView.imageUrls.length > 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(
                            420,
                            Math.max(220, (detailScroll.availableWidth - 56) * 0.62)
                        )
                        radius: 10
                        color: Constants.secondaryCardBackgroundColor(rootWindow.isDarkMode)
                        clip: true

                        SwipeView {
                            id: imageGallery
                            anchors.fill: parent

                            Repeater {
                                model: newsDetailView.imageUrls

                                delegate: Item {
                                    id: galleryPage

                                    required property int index
                                    required property string modelData

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        source: galleryPage.modelData
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        cache: true
                                    }

                                    TapHandler {
                                        onTapped: newsDetailView.openImageViewer()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: newsDetailView.imageUrls.length > 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            width: galleryIndicator.implicitWidth + 16
                            height: galleryIndicator.implicitHeight + 8
                            radius: height / 2
                            color: "#99000000"

                            PageIndicator {
                                id: galleryIndicator
                                anchors.centerIn: parent
                                count: imageGallery.count
                                currentIndex: imageGallery.currentIndex
                            }
                        }
                    }

                    AppBusyIndicator {
                        running: djkbNewsScraper.detailLoading
                        visible: running
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        visible: djkbNewsScraper.detailErrorString !== ""
                        text: "Der vollständige Artikel konnte nicht geladen werden."
                        color: Constants.destructiveColor
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }

                    Label {
                        text: newsDetailView.bodyText
                        font.pixelSize: 16
                        lineHeight: 1.3
                        color: Constants.primaryTextColor(rootWindow.isDarkMode)
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    SourceAttribution {
                        sourceName: "Originalartikel beim DJKB"
                        sourceUrl: newsDetailView.articleUrl
                        Layout.fillWidth: true
                    }
                }
            }

            Item {
                Layout.preferredHeight: 24
            }
        }
    }

    Popup {
        id: imageViewer

        parent: Overlay.overlay
        x: 0
        y: 0
        width: parent ? parent.width : 0
        height: parent ? parent.height : 0
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape
        onOpened: viewerSurface.y = 0
        onClosed: fullScreenGallery.reset()

        background: Rectangle {
            color: "black"
            opacity: Math.max(0.25, 0.96 - viewerSurface.y
                              / Math.max(1, imageViewer.height) * 1.4)
        }

        contentItem: Item {
            Item {
                id: viewerSurface

                x: 0
                y: 0
                width: parent.width
                height: parent.height

                SwipeView {
                id: fullScreenGallery

                property real currentZoomScale: 1
                property int zoomResetRevision: 0

                function reset() {
                    ++zoomResetRevision
                    currentZoomScale = 1
                    currentIndex = 0
                }

                anchors.fill: parent
                interactive: currentZoomScale <= 1.01 && !dismissDrag.active
                onCurrentIndexChanged: currentZoomScale = 1

                Repeater {
                    id: fullScreenRepeater

                    model: newsDetailView.imageUrls

                    delegate: Item {
                        id: fullScreenPage

                        required property int index
                        required property string modelData
                        readonly property bool zoomed: zoomTarget.scale > 1.01
                        readonly property int zoomResetRevision:
                            fullScreenGallery.zoomResetRevision
                        onZoomResetRevisionChanged: resetZoom()

                        function clampZoomPosition() {
                            const horizontalLimit = width * (zoomTarget.scale - 1) / 2
                            const verticalLimit = height * (zoomTarget.scale - 1) / 2
                            zoomTarget.x = Math.max(-horizontalLimit,
                                                    Math.min(horizontalLimit, zoomTarget.x))
                            zoomTarget.y = Math.max(-verticalLimit,
                                                    Math.min(verticalLimit, zoomTarget.y))
                        }

                        function resetZoom() {
                            zoomTarget.scale = 1
                            zoomTarget.x = 0
                            zoomTarget.y = 0
                        }

                        Item {
                            id: zoomTarget
                            x: 0
                            y: 0
                            width: parent.width
                            height: parent.height
                            transformOrigin: Item.Center
                            onScaleChanged: {
                                fullScreenPage.clampZoomPosition()
                                if (fullScreenPage.index === fullScreenGallery.currentIndex)
                                    fullScreenGallery.currentZoomScale = scale
                            }

                            Image {
                                anchors.fill: parent
                                anchors.margins: 18
                                source: fullScreenPage.modelData
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: true
                            }

                            PinchHandler {
                                id: imagePinch
                                target: zoomTarget
                                scaleAxis.minimum: 1
                                scaleAxis.maximum: 5
                                rotationAxis.enabled: false
                                onActiveChanged: {
                                    if (!active)
                                        fullScreenPage.clampZoomPosition()
                                }
                            }

                            DragHandler {
                                target: zoomTarget
                                enabled: fullScreenPage.zoomed
                                xAxis.minimum: -fullScreenPage.width
                                               * (zoomTarget.scale - 1) / 2
                                xAxis.maximum: fullScreenPage.width
                                               * (zoomTarget.scale - 1) / 2
                                yAxis.minimum: -fullScreenPage.height
                                               * (zoomTarget.scale - 1) / 2
                                yAxis.maximum: fullScreenPage.height
                                               * (zoomTarget.scale - 1) / 2
                            }

                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                gesturePolicy: TapHandler.WithinBounds
                                onDoubleTapped: {
                                    if (fullScreenPage.zoomed)
                                        fullScreenPage.resetZoom()
                                    else
                                        zoomTarget.scale = 2
                                }
                            }
                        }
                    }
                }
            }

            ToolButton {
                id: closeImageViewerButton

                text: "x"
                width: 40
                height: 40
                padding: 0
                x: parent.width - width - 32
                y: 32
                z: 10
                onClicked: imageViewer.close()

                background: Rectangle {
                    radius: 8
                    color: closeImageViewerButton.down ? "#A83232"
                                                       : closeImageViewerButton.hovered ? "#D95656"
                                                                                        : "#C74444"
                    border.color: "#CCFFFFFF"
                    border.width: 1
                }

                contentItem: Label {
                    text: closeImageViewerButton.text
                    color: "white"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            SourceAttribution {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                sourceName: "DJKB"
                sourceUrl: newsDetailView.articleUrl
                lightText: true
                z: 10
            }

                Rectangle {
                visible: newsDetailView.imageUrls.length > 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                width: fullScreenIndicator.implicitWidth + 18
                height: fullScreenIndicator.implicitHeight + 10
                radius: height / 2
                color: "#99000000"
                z: 10

                PageIndicator {
                    id: fullScreenIndicator
                    anchors.centerIn: parent
                    count: fullScreenGallery.count
                    currentIndex: fullScreenGallery.currentIndex
                }
            }

                DragHandler {
                    id: dismissDrag

                    target: viewerSurface
                    enabled: fullScreenGallery.currentZoomScale <= 1.01
                    xAxis.enabled: false
                    yAxis.minimum: 0
                    yAxis.maximum: viewerSurface.height
                    onActiveChanged: {
                        if (active)
                            dismissReturnAnimation.stop()
                        else if (viewerSurface.y
                                 > Math.min(140, viewerSurface.height * 0.18)) {
                            imageViewer.close()
                            viewerSurface.y = 0
                        } else {
                            dismissReturnAnimation.restart()
                        }
                    }
                }
            }

            NumberAnimation {
                id: dismissReturnAnimation

                target: viewerSurface
                property: "y"
                to: 0
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
}
