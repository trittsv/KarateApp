// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls

ToolBar {
    implicitHeight: 44
    leftPadding: 12
    rightPadding: 12

    background: Rectangle {
        implicitHeight: 44
        color: Constants.safeEdgeColor(rootWindow.isDarkMode)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Constants.separatorColor(rootWindow.isDarkMode)
        }
    }
}
