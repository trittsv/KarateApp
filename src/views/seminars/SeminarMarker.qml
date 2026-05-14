// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtLocation
import QtPositioning

MapQuickItem {
    id: markerItem

    property var seminar: ({})
    property int seminarId: -1
    property string eventType: "seminar"
    property var eventTypeFilters: []
    property bool selected: false

    signal clicked(var marker)

    visible: eventTypeFilters.indexOf(eventType) !== -1
    z: selected ? 150 : 90
    anchorPoint.x: sourceItem.width / 2
    anchorPoint.y: sourceItem.height
    coordinate: QtPositioning.coordinate(0, 0)

    sourceItem: Item {
        width: markerItem.eventType === "seminar" ? marker.width : 28
        height: markerItem.eventType === "seminar" ? marker.height : 28

        Rectangle {
            id: marker
            visible: markerItem.eventType === "seminar"
            width: 22
            height: 22
            radius: 11
            color: markerItem.selected ? "#D70015" : "black"
            border.color: "white"
            border.width: 3
        }

        Item {
            id: competitionMarker
            visible: markerItem.eventType === "competition"
            width: 28
            height: 28

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: markerItem.selected ? "#D70015" : "black"
                border.color: "white"
                border.width: 3
            }

            Rectangle {
                id: cupBowl
                x: 9
                y: 7
                width: 10
                height: 7
                radius: 3
                color: "#FFD54A"
            }

            Rectangle {
                x: 10
                y: 12
                width: 8
                height: 3
                radius: 1
                color: "#FFD54A"
            }

            Rectangle {
                x: 6
                y: 9
                width: 5
                height: 6
                radius: 3
                color: "transparent"
                border.color: "#FFD54A"
                border.width: 2
            }

            Rectangle {
                x: 17
                y: 9
                width: 5
                height: 6
                radius: 3
                color: "transparent"
                border.color: "#FFD54A"
                border.width: 2
            }

            Rectangle {
                x: 13
                y: 15
                width: 2
                height: 5
                radius: 1
                color: "#FFD54A"
            }

            Rectangle {
                x: 9
                y: 20
                width: 10
                height: 3
                radius: 1
                color: "#FFD54A"
            }
        }

        Item {
            id: nationalTeamMarker
            visible: markerItem.eventType === "national_team"
            width: 28
            height: 28

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: markerItem.selected ? "#D70015" : "white"
                border.color: "white"
                border.width: 2
            }

            Canvas {
                anchors.centerIn: parent
                width: 20
                height: 20

                onPaint: {
                    const context = getContext("2d")
                    const stripeHeight = height / 3

                    context.reset()
                    context.beginPath()
                    context.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2)
                    context.clip()

                    context.fillStyle = "#000000"
                    context.fillRect(0, 0, width, stripeHeight)
                    context.fillStyle = "#DD0000"
                    context.fillRect(0, stripeHeight, width, stripeHeight)
                    context.fillStyle = "#FFCE00"
                    context.fillRect(0, stripeHeight * 2, width, height - stripeHeight * 2)
                }
            }
        }

        Item {
            id: regionalTeamMarker
            visible: markerItem.eventType === "regional_team"
            width: 28
            height: 28

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: markerItem.selected ? "#D70015" : "#111111"
                border.color: "white"
                border.width: 3
            }

            Rectangle {
                anchors.centerIn: parent
                width: 15
                height: 2
                radius: 1
                color: "white"
            }

            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: 15
                radius: 1
                color: "white"
            }

            Repeater {
                model: [
                    { "x": 6, "y": 6 },
                    { "x": 18, "y": 6 },
                    { "x": 6, "y": 18 },
                    { "x": 18, "y": 18 }
                ]

                delegate: Rectangle {
                    required property var modelData

                    x: modelData.x
                    y: modelData.y
                    width: 4
                    height: 4
                    radius: 2
                    color: "white"
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 7
                radius: width / 2
                color: "white"
                border.color: markerItem.selected ? "#D70015" : "#111111"
                border.width: 1
            }
        }

        Item {
            id: trainingMarker
            visible: markerItem.eventType === "training"
            width: 28
            height: 28

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: markerItem.selected ? "#D70015" : "white"
                border.color: markerItem.selected ? "white" : "#111111"
                border.width: 2
            }

            Canvas {
                anchors.centerIn: parent
                width: 18
                height: 16

                onPaint: {
                    const context = getContext("2d")
                    const iconColor = markerItem.selected ? "#FFFFFF" : "#111111"

                    context.reset()
                    context.fillStyle = iconColor

                    context.beginPath()
                    context.moveTo(0, 5)
                    context.lineTo(width / 2, 1)
                    context.lineTo(width, 5)
                    context.lineTo(width / 2, 9)
                    context.closePath()
                    context.fill()

                    context.fillRect(4, 8, 10, 4)
                    context.fillRect(width - 2, 5, 1.5, 8)

                    context.beginPath()
                    context.arc(width - 1.25, 14, 1.5, 0, Math.PI * 2)
                    context.fill()
                }
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked: function(mouse) {
                mouse.accepted = true
                markerItem.clicked(markerItem)
            }
        }
    }
}
