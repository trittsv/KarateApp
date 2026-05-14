// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import ".."

Page {
    id: photosView

    required property var mainContentStackView
    required property string albumTitle
    required property string albumUrl
    required property int expectedPhotoCount
    property int selectedPhotoIndex: -1
    readonly property int columnCount: width >= 900 ? 5
                                       : width >= 600 ? 4 : 3

    function openPhoto(index) {
        selectedPhotoIndex = index
        fullScreenGallery.visible = false
        fullScreenGallery.resetTo(index)
        photoViewer.open()
    }

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    Component.onCompleted: {
        galleryPhotosModel.clear()
        djkbGalleryScraper.loadFirstPhotoPage(albumUrl)
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
                text: photosView.albumTitle
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 90
                    rightMargin: 90
                    verticalCenter: parent.verticalCenter
                }
            }

            AppBusyIndicator {
                running: djkbGalleryScraper.photosLoading
                width: 32
                height: 32
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    GridView {
        id: photoGrid
        anchors.fill: parent
        clip: true
        model: galleryPhotosModel
        cellWidth: width / photosView.columnCount
        cellHeight: cellWidth
        topMargin: 4
        bottomMargin: 8

        onAtYEndChanged: {
            if (atYEnd && galleryPhotosModel.count > 0
                    && djkbGalleryScraper.photosHasMore
                    && !djkbGalleryScraper.photosLoading)
                djkbGalleryScraper.loadMorePhotos()
        }

        delegate: ItemDelegate {
            id: photoItem

            required property int index
            required property string thumbnailUrl

            width: photoGrid.cellWidth
            height: photoGrid.cellHeight
            padding: 3

            background: Item {}

            contentItem: Rectangle {
                color: Constants.secondaryCardBackgroundColor(rootWindow.isDarkMode)

                Image {
                    anchors.fill: parent
                    source: photoItem.thumbnailUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
            }

            onClicked: photosView.openPhoto(index)
        }

        footer: Item {
            width: photoGrid.width
            height: footerColumn.implicitHeight + 20

            Column {
                id: footerColumn
                width: parent.width
                spacing: 8

                Label {
                    visible: djkbGalleryScraper.photosErrorString !== ""
                    width: parent.width
                    text: "Weitere Bilder konnten nicht geladen werden."
                    color: Constants.destructiveColor
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Button {
                    visible: djkbGalleryScraper.photosHasMore
                             || djkbGalleryScraper.photosErrorString !== ""
                    enabled: !djkbGalleryScraper.photosLoading
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: djkbGalleryScraper.photosLoading
                          ? "Lade..." : "Mehr Bilder laden"
                    onClicked: djkbGalleryScraper.loadMorePhotos()
                }

                Label {
                    visible: galleryPhotosModel.count > 0
                             && !djkbGalleryScraper.photosHasMore
                    width: parent.width
                    text: galleryPhotosModel.count + " von "
                          + photosView.expectedPhotoCount + " Bildern geladen"
                    color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Popup {
        id: photoViewer

        parent: Overlay.overlay
        x: 0
        y: 0
        width: parent ? parent.width : 0
        height: parent ? parent.height : 0
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape
        onOpened: {
            viewerSurface.y = 0
            fullScreenGallery.resetTo(photosView.selectedPhotoIndex)
            Qt.callLater(function() {
                fullScreenGallery.visible = true
            })
        }
        onClosed: {
            fullScreenGallery.visible = false
            fullScreenGallery.resetTo(0)
        }

        background: Rectangle {
            color: "black"
            opacity: Math.max(0.25, 0.96 - viewerSurface.y
                              / Math.max(1, photoViewer.height) * 1.4)
        }

        contentItem: Item {
            Item {
                id: viewerSurface

                x: 0
                y: 0
                width: parent.width
                height: parent.height

                ListView {
                    id: fullScreenGallery

                    property real currentZoomScale: 1
                    property int zoomResetRevision: 0
                    property bool pendingAdvance: false
                    property int pendingTargetIndex: -1

                    function boundedIndex(index) {
                        return Math.max(
                            0,
                            Math.min(index, galleryPhotosModel.count - 1)
                        )
                    }

                    function resetTo(index) {
                        ++zoomResetRevision
                        currentZoomScale = 1
                        pendingAdvance = false
                        pendingTargetIndex = -1
                        jumpTo(index)
                    }

                    function jumpTo(index) {
                        currentIndex = boundedIndex(index)
                        contentX = currentIndex * width
                    }

                    function moveTo(index) {
                        currentIndex = boundedIndex(index)
                        positionViewAtIndex(currentIndex, ListView.Beginning)
                    }

                    function preloadNextPage() {
                        if (currentIndex >= count - 3
                                && djkbGalleryScraper.photosHasMore
                                && !djkbGalleryScraper.photosLoading)
                            djkbGalleryScraper.loadMorePhotos()
                    }

                    function showNext() {
                        if (currentIndex + 1 < count) {
                            moveTo(currentIndex + 1)
                            return
                        }

                        if (!djkbGalleryScraper.photosHasMore)
                            return

                        pendingAdvance = true
                        pendingTargetIndex = count
                        if (!djkbGalleryScraper.photosLoading)
                            djkbGalleryScraper.loadMorePhotos()
                    }

                    anchors.fill: parent
                    model: galleryPhotosModel
                    orientation: ListView.Horizontal
                    snapMode: ListView.SnapOneItem
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0
                    highlightResizeDuration: 0
                    interactive: currentZoomScale <= 1.01 && !dismissDrag.active
                    onMovementEnded: {
                        currentIndex = boundedIndex(Math.round(contentX / Math.max(1, width)))
                        positionViewAtIndex(currentIndex, ListView.Beginning)
                    }
                    onCurrentIndexChanged: {
                        currentZoomScale = 1
                        photosView.selectedPhotoIndex = currentIndex
                        preloadNextPage()
                    }

                    Connections {
                        target: galleryPhotosModel

                        function onCountChanged() {
                            if (fullScreenGallery.pendingAdvance
                                    && galleryPhotosModel.count
                                    > fullScreenGallery.pendingTargetIndex) {
                                fullScreenGallery.moveTo(
                                    fullScreenGallery.pendingTargetIndex
                                )
                                fullScreenGallery.pendingAdvance = false
                                fullScreenGallery.pendingTargetIndex = -1
                            }
                        }
                    }

                    delegate: Item {
                            id: fullScreenPage

                            required property int index
                            required property string imageUrl
                            readonly property bool zoomed: zoomTarget.scale > 1.01
                            readonly property int zoomResetRevision:
                                fullScreenGallery.zoomResetRevision
                            onZoomResetRevisionChanged: resetZoom()

                            function clampZoomPosition() {
                                const horizontalLimit =
                                    width * (zoomTarget.scale - 1) / 2
                                const verticalLimit =
                                    height * (zoomTarget.scale - 1) / 2
                                zoomTarget.x = Math.max(
                                    -horizontalLimit,
                                    Math.min(horizontalLimit, zoomTarget.x)
                                )
                                zoomTarget.y = Math.max(
                                    -verticalLimit,
                                    Math.min(verticalLimit, zoomTarget.y)
                                )
                            }

                            function resetZoom() {
                                zoomTarget.scale = 1
                                zoomTarget.x = 0
                                zoomTarget.y = 0
                            }

                            width: fullScreenGallery.width
                            height: fullScreenGallery.height

                            Item {
                                id: zoomTarget

                                x: 0
                                y: 0
                                width: parent.width
                                height: parent.height
                                transformOrigin: Item.Center
                                onScaleChanged: {
                                    fullScreenPage.clampZoomPosition()
                                    if (fullScreenPage.index
                                            === fullScreenGallery.currentIndex)
                                        fullScreenGallery.currentZoomScale = scale
                                }

                                Image {
                                    id: fullImage

                                    anchors.fill: parent
                                    anchors.margins: 18
                                    source: fullScreenPage.imageUrl
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                }

                                AppBusyIndicator {
                                    anchors.centerIn: parent
                                    running: fullImage.status === Image.Loading
                                }

                                PinchHandler {
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

                ToolButton {
                    id: closePhotoViewerButton

                    text: "x"
                    width: 40
                    height: 40
                    padding: 0
                    x: parent.width - width - 32
                    y: 32
                    z: 10
                    onClicked: photoViewer.close()

                    background: Rectangle {
                        radius: 8
                        color: closePhotoViewerButton.down ? "#A83232"
                                                           : closePhotoViewerButton.hovered ? "#D95656"
                                                                                           : "#C74444"
                        border.color: "#CCFFFFFF"
                        border.width: 1
                    }

                    contentItem: Label {
                        text: closePhotoViewerButton.text
                        color: "white"
                        font.pixelSize: 20
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ToolButton {
                    visible: fullScreenGallery.currentIndex > 0
                    text: "\u2039"
                    font.pixelSize: 38
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    z: 10
                    onClicked: fullScreenGallery.moveTo(
                        fullScreenGallery.currentIndex - 1
                    )
                }

                ToolButton {
                    visible: fullScreenGallery.currentIndex + 1
                             < galleryPhotosModel.count
                             || djkbGalleryScraper.photosHasMore
                    enabled: !fullScreenGallery.pendingAdvance
                    text: "\u203A"
                    font.pixelSize: 38
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    z: 10
                    onClicked: fullScreenGallery.showNext()
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    width: counterLabel.implicitWidth + 18
                    height: counterLabel.implicitHeight + 10
                    radius: height / 2
                    color: "#99000000"
                    z: 10

                    Label {
                        id: counterLabel
                        anchors.centerIn: parent
                        text: (fullScreenGallery.currentIndex + 1)
                              + " / " + galleryPhotosModel.count
                        color: "white"
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
                        if (active) {
                            dismissReturnAnimation.stop()
                        } else if (viewerSurface.y
                                   > Math.min(140, viewerSurface.height * 0.18)) {
                            photoViewer.close()
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
