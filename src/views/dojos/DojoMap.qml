// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtLocation
import QtPositioning

Item {
    id: dojoMapView

    property alias plugin: map.plugin
    property var model: null
    property bool active: true
    property var selectedDojo: ({})
    property int selectedDojoId: -1

    signal dojoSelected(var dojo)
    signal dojoOpenRequested(var dojo)

    Map {
        id: map

        anchors.fill: parent
        center: QtPositioning.coordinate(51.24107595267345, 10.412607376825193)
        zoomLevel: 6
        activeMapType: supportedMapTypes[supportedMapTypes.length - 1]

        property geoCoordinate startCentroid

        MapItemView {
            model: dojoMapView.active ? dojoMapView.model : null

            delegate: DojoMarker {
                selected: dojoMapView.selectedDojoId === dojoId
                onClicked: function(markerItem) {
                    const dojo = markerItem.dojoData()
                    if (dojoMapView.selectedDojoId === markerItem.dojoId) {
                        dojoMapView.selectedDojoId = -1
                        dojoMapView.selectedDojo = ({})
                        return
                    }

                    dojoMapView.selectedDojoId = markerItem.dojoId
                    dojoMapView.selectedDojo = dojo
                    dojoMapView.dojoSelected(dojo)
                }
            }
        }

        DragHandler {
            id: dragHandler
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
                             | PointerHandler.ApprovesTakeOverByAnything

            onActiveChanged: {
                if (active)
                    map.startCentroid = map.toCoordinate(
                        dragHandler.centroid.position,
                        false
                    )
            }

            onCentroidChanged: {
                if (active)
                    map.alignCoordinateToPoint(
                        map.startCentroid,
                        dragHandler.centroid.position
                    )
            }
        }

        PinchHandler {
            id: pinch
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
                             | PointerHandler.ApprovesTakeOverByAnything

            onActiveChanged: {
                if (active)
                    map.startCentroid = map.toCoordinate(
                        pinch.centroid.position,
                        false
                    )
            }

            onScaleChanged: function(delta) {
                map.zoomLevel += Math.log2(delta)
                map.alignCoordinateToPoint(
                    map.startCentroid,
                    pinch.centroid.position
                )
            }

            onRotationChanged: function(delta) {
                map.bearing -= delta
                map.alignCoordinateToPoint(
                    map.startCentroid,
                    pinch.centroid.position
                )
            }
        }

        WheelHandler {
            acceptedDevices: Qt.platform.pluginName === "cocoa"
                             || Qt.platform.pluginName === "wayland"
                             ? PointerDevice.Mouse | PointerDevice.TouchPad
                             : PointerDevice.Mouse
            rotationScale: 1 / 120
            property: "zoomLevel"
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

        DojoMapCard {
            dojo: dojoMapView.selectedDojo
            onOpenRequested: function(dojo) {
                dojoMapView.dojoOpenRequested(dojo)
            }
        }
    }
}
