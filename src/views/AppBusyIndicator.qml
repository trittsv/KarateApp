// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick

Item {
    id: indicator

    property bool running: false

    implicitWidth: 28
    implicitHeight: 28
    visible: running

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        rotation: 0

        Repeater {
            model: 12

            delegate: Item {
                required property int index

                anchors.fill: parent
                rotation: index * 30

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: Math.max(2, parent.width * 0.08)
                    height: Math.max(5, parent.height * 0.24)
                    radius: width / 2
                    color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                    opacity: 0.15 + index * 0.07
                }
            }
        }

        RotationAnimator on rotation {
            running: indicator.running
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
        }
    }
}
