// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

import ".."

Item {
    id: seminarMapView

    property alias plugin: map.plugin
    property var userCoordinate: QtPositioning.coordinate(0, 0)
    property bool hasUserPosition: false
    property real radiusKm: 100
    property var selectedMarker: null
    property int selectedSeminarId: -1
    property var selectedSeminar: ({})
    property var seminarMarkers: []

    signal radiusFilterToggleRequested()
    signal selectedSeminarOpenRequested(var seminar)

    function addMarker(marker) {
        map.addMapItem(marker)
        seminarMarkers.push(marker)
    }

    function clearSeminarMarkers() {
        for (let i = 0; i < seminarMarkers.length; i++) {
            map.removeMapItem(seminarMarkers[i])
            seminarMarkers[i].destroy()
        }

        seminarMarkers = []
    }

    function centerOnUserPosition() {
        if (!hasUserPosition || !userCoordinate || !userCoordinate.isValid)
            return

        map.center = userCoordinate
        map.bearing = 0
        map.zoomLevel = 8
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Map {
            id: map
            anchors.fill: parent
            center: QtPositioning.coordinate(51.24107595267345, 10.412607376825193)
            zoomLevel: 6
            activeMapType: supportedMapTypes[supportedMapTypes.length - 1]

            property geoCoordinate startCentroid

            MapQuickItem {
                id: myLocationMarker
                visible: seminarMapView.hasUserPosition
                coordinate: seminarMapView.userCoordinate
                anchorPoint.x: 10
                anchorPoint.y: 10
                z: 99

                sourceItem: Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: "blue"
                    border.color: "white"
                    border.width: 3
                }
            }

            MapCircle {
                center: seminarMapView.userCoordinate
                radius: seminarMapView.radiusKm * 1000
                visible: seminarMapView.radiusKm > 0
                         && seminarMapView.hasUserPosition
                         && seminarMapView.userCoordinate
                         && seminarMapView.userCoordinate.isValid
                color: rootWindow.isDarkMode ? "#225DADE2" : "#285DADE2"
                border.color: Constants.locationMarkerColor
                border.width: 2
            }

            DragHandler {
                id: dragHandler
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything | PointerHandler.ApprovesTakeOverByAnything

                onActiveChanged: {
                    if (active)
                        map.startCentroid = map.toCoordinate(dragHandler.centroid.position, false)
                }

                onCentroidChanged: {
                    if (active)
                        map.alignCoordinateToPoint(map.startCentroid, dragHandler.centroid.position)
                }
            }

            PinchHandler {
                id: pinch
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything | PointerHandler.ApprovesTakeOverByAnything

                onActiveChanged: {
                    if (active)
                        map.startCentroid = map.toCoordinate(pinch.centroid.position, false)
                }

                onScaleChanged: function(delta) {
                    map.zoomLevel += Math.log2(delta)
                    map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
                }

                onRotationChanged: function(delta) {
                    map.bearing -= delta
                    map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
                }
            }

            WheelHandler {
                id: wheel
                acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                                 ? PointerDevice.Mouse | PointerDevice.TouchPad
                                 : PointerDevice.Mouse
                rotationScale: 1 / 120
                property: "zoomLevel"
            }

            RoundButton {
                id: centerOnUserButton
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 14
                anchors.bottomMargin: rootWindow.isDesktop
                                      ? 34
                                      : Math.max(
                                            66,
                                            rootWindow.SafeArea.margins.bottom
                                            + 64
                                        )
                width: 42
                height: 42
                enabled: seminarMapView.hasUserPosition
                         && seminarMapView.userCoordinate
                         && seminarMapView.userCoordinate.isValid
                z: 100
                padding: 10

                background: Rectangle {
                    radius: width / 2
                    color: centerOnUserButton.down
                           ? Constants.pressedColor(rootWindow.isDarkMode)
                           : Constants.cardBackgroundColor(rootWindow.isDarkMode)
                    border.color: Constants.borderColor(rootWindow.isDarkMode)
                    border.width: 1
                }

                contentItem: Item {
                    Canvas {
                        anchors.fill: parent
                        opacity: centerOnUserButton.enabled ? 1 : 0.45

                        onPaint: {
                            const context = getContext("2d")

                            context.reset()
                            context.beginPath()
                            context.moveTo(width * 0.5, 0)
                            context.lineTo(width, height)
                            context.lineTo(width * 0.5, height * 0.72)
                            context.lineTo(0, height)
                            context.closePath()
                            context.fillStyle = Constants.locationMarkerColor
                            context.fill()
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 1.35
                        height: 3
                        radius: height / 2
                        rotation: -45
                        color: Constants.destructiveColor
                        visible: !centerOnUserButton.enabled
                    }
                }

                onClicked: seminarMapView.centerOnUserPosition()
            }

            RoundButton {
                id: compassButton
                anchors.right: centerOnUserButton.right
                anchors.bottom: centerOnUserButton.top
                anchors.bottomMargin: 10
                width: 42
                height: 42
                z: 100
                padding: 9

                background: Rectangle {
                    radius: width / 2
                    color: compassButton.down
                           ? Constants.pressedColor(rootWindow.isDarkMode)
                           : Constants.cardBackgroundColor(rootWindow.isDarkMode)
                    border.color: Constants.borderColor(rootWindow.isDarkMode)
                    border.width: 1
                }

                contentItem: Item {
                    rotation: -map.bearing

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: -6
                        text: "N"
                        font.pixelSize: 7
                        font.bold: true
                        color: Constants.destructiveColor
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.rightMargin: -6
                        anchors.verticalCenter: parent.verticalCenter
                        text: "O"
                        font.pixelSize: 7
                        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -6
                        text: "S"
                        font.pixelSize: 7
                        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                    }

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: -6
                        anchors.verticalCenter: parent.verticalCenter
                        text: "W"
                        font.pixelSize: 7
                        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                    }

                    Canvas {
                        id: compassNeedle

                        property color southNeedleColor:
                            Constants.secondaryTextColor(rootWindow.isDarkMode)

                        anchors.centerIn: parent
                        width: parent.width * 0.64
                        height: parent.height * 0.64

                        onSouthNeedleColorChanged: requestPaint()

                        onPaint: {
                            const context = getContext("2d")

                            context.reset()

                            context.beginPath()
                            context.moveTo(width / 2, 0)
                            context.lineTo(width * 0.72, height / 2)
                            context.lineTo(width / 2, height * 0.43)
                            context.lineTo(width * 0.28, height / 2)
                            context.closePath()
                            context.fillStyle = Constants.destructiveColor
                            context.fill()

                            context.beginPath()
                            context.moveTo(width / 2, height)
                            context.lineTo(width * 0.72, height / 2)
                            context.lineTo(width / 2, height * 0.57)
                            context.lineTo(width * 0.28, height / 2)
                            context.closePath()
                            context.fillStyle = southNeedleColor
                            context.fill()
                        }
                    }
                }
                onClicked: map.bearing = 0
            }

            RoundButton {
                id: radiusFilterButton
                anchors.right: compassButton.right
                anchors.bottom: compassButton.top
                anchors.bottomMargin: 10
                visible: seminarMapView.hasUserPosition
                         && seminarMapView.userCoordinate
                         && seminarMapView.userCoordinate.isValid
                width: 42
                height: 42
                z: 100
                padding: 0

                background: Rectangle {
                    radius: width / 2
                    color: radiusFilterButton.down
                           ? Constants.pressedColor(rootWindow.isDarkMode)
                           : Constants.cardBackgroundColor(rootWindow.isDarkMode)
                    border.color: seminarMapView.radiusKm > 0
                                  ? Constants.locationMarkerColor
                                  : Constants.borderColor(rootWindow.isDarkMode)
                    border.width: seminarMapView.radiusKm > 0 ? 2 : 1
                }

                contentItem: Item {
                    opacity: seminarMapView.radiusKm > 0 ? 1 : 0.45

                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: width / 2
                        color: "transparent"
                        border.color: Constants.locationMarkerColor
                        border.width: 2
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: width / 2
                        color: Constants.locationMarkerColor
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 3
                        radius: height / 2
                        rotation: -45
                        color: Constants.destructiveColor
                        visible: seminarMapView.radiusKm <= 0
                    }
                }

                onClicked: seminarMapView.radiusFilterToggleRequested()
            }

            Shortcut {
                enabled: map.zoomLevel < map.maximumZoomLevel
                sequence: [StandardKey.ZoomIn]
                onActivated: map.zoomLevel = Math.round(map.zoomLevel + 1)
            }

            Shortcut {
                enabled: map.zoomLevel > map.minimumZoomLevel
                sequence: [StandardKey.ZoomOut]
                onActivated: map.zoomLevel = Math.round(map.zoomLevel - 1)
            }

            SeminarMapCard {
                selectedMarker: seminarMapView.selectedMarker
                selectedSeminarId: seminarMapView.selectedSeminarId
                selectedSeminar: seminarMapView.selectedSeminar
                onOpenRequested: function(seminar) {
                    seminarMapView.selectedSeminarOpenRequested(seminar)
                }
            }
        }
    }
}
