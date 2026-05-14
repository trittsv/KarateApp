// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

import "utils"

ApplicationWindow {
    id: rootWindow
    visible: true
    width: isDesktop ? 1000 : 420
    height: 680
    title: "KarateApp"
    flags: Qt.Window | Qt.ExpandedClientAreaHint
    bottomPadding: isDesktop ? SafeArea.margins.bottom : 0

    property bool isDarkMode: false
    property bool manualAppearance: false
    property bool isDesktop: Qt.platform.os !== "ios" && Qt.platform.os !== "android"
    
    property var pendingAppointment: null
    property var addressQueue: []

    function handleRotationChange() {
        if (Screen.primaryOrientation === Qt.PortraitOrientation) {
            console.log("Portrait orientation")
        } else if (Screen.primaryOrientation === Qt.LandscapeOrientation) {
            console.log("Landscape orientation")
        } else {
            console.log("Unknown Orientation")
        }
    }

    menuBar: MenuBar {
        visible: Qt.platform.os === "osx"

        Menu {
            title: "Help"

            MenuItem {
                text: "About"
                onTriggered: aboutWindow.visible = true
            }
        }
    }

    SystemPalette {
        id: mySysPalette

        onDarkChanged: {
            rootWindow.isDarkMode = getDarkMode()
        }
    }

    function getDarkMode() {
        var isDarkModeVal = mySysPalette.windowText.hsvValue > mySysPalette.window.hsvValue
        console.log("qt build in darkmode check: isDarkMode", isDarkModeVal)
        return isDarkModeVal
    }

    Component.onCompleted: {
        console.log("Running on platform.os:", Qt.platform.os)

        // Safe edges: Only on ios, not needed on android for now
        // Requires to manage safe space manually with full screen
        //if (Qt.platform.os === "ios") {
        //    flags = Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint;
        //}
        rootWindow.isDarkMode = getDarkMode()
        handleRotationChange()

        showMainContent()

        console.log("Constants.tabBarIconSize", Constants.tabBarIconSize)
        console.log("Constants.backgroundColor", Constants.backgroundColor)
    }

    background: Rectangle {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent

            onWidthChanged: {
                if (rootWindow.width === Screen.width || rootWindow.width === Screen.height) {
                    handleRotationChange()
                }
            }

            color: Constants.safeEdgeColor(isDarkMode)
        }

        Rectangle {
            id: rootOverrideRectangle
            visible: false
            anchors.fill: parent
        }
    }

    function resetEdgeColor() {
        if (isDesktop)
            return

        rootOverrideRectangle.visible = false
    }

    function setEdgeColor(color) {
        if (isDesktop)
            return

        rootOverrideRectangle.color = color
        rootOverrideRectangle.visible = true
    }

    function switchView() {
        isDesktop = !isDesktop
        showMainContent()
    }

    function clearNavigation() {
        for (var i = navigationController.stack.length - 1; i >= 0; --i) {
            if (navigationController.stack[i])
                navigationController.stack[i].destroy()
        }

        navigationController.stack = []
    }

    function replaceRootPage(componentUrl, props) {
        clearNavigation()

        var component = Qt.createComponent(componentUrl)

        if (component.status === Component.Ready) {
            navigationController.push(component, props || {})
        } else if (component.status === Component.Error) {
            console.error("Failed to load component:", component.errorString())
        } else {
            component.statusChanged.connect(function() {
                if (component.status === Component.Ready) {
                    navigationController.push(component, props || {})
                } else if (component.status === Component.Error) {
                    console.error("Failed to load component:", component.errorString())
                }
            })
        }
    }

    function showMainContent() {
        if (isDesktop) {
            replaceRootPage("qrc:/KarateApp/src/views/MainContentViewDesktop.qml", {
                mainContentStackView: navigationController,
                navigationController: navigationController
            })
            return
        }

        replaceRootPage("qrc:/KarateApp/src/views/MainContentViewMobile.qml", {
            mainContentStackView: navigationController,
            navigationController: navigationController
        })
    }

    Shortcut {
        enabled: Qt.platform.os === "android"
        sequences: [StandardKey.Back]
        context: Qt.ApplicationShortcut

        onActivated: {
            if (navigationController.canPop()) {
                navigationController.pop()
                rootWindow.resetEdgeColor()
            } else {
                ApplicationHelper.moveToBackground()
            }
        }
    }

    Plugin {
        id: mapPlugin
        name: "osm"

        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "http://tile.thunderforest.com/atlas/%z/%x/%y.png?apikey=" + THUNDERFOREST_API_KEY + "&fake=.png"
        }

        PluginParameter {
            name: "osm.mapping.providersrepository.disabled"
            value: true
        }

        PluginParameter {
            name: "osm.mapping.copyright"
            value: "Map © Thunderforest | Data © OpenStreetMap contributors"
        }
    }

    Dialog {
        id: alertDialog
        title: "Alert"
        anchors.centerIn: parent
        standardButtons: Dialog.Ok

        contentItem: Label {
            id: alertText
            text: "This is an alert message!"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    RowLayout {
        id: rootRowLayout
        anchors.fill: parent
        spacing: 0

        Item {
            id: leftRootItem
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    id: topRootItem
                }

                Item {
                    id: safeContent
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    NavigationController {
                        id: navigationController
                        anchors.fill: parent

                        onPagePopped: {
                            rootWindow.resetEdgeColor()
                        }
                    }
                }

                Item {
                    id: bottomRootItem
                }
            }
        }

        Item {
            id: rightRootItem
        }
    }

    function enableSwipeBack() {
        // Nicht mehr nötig.
        // NavigationController macht Swipe-Back selbst.
    }

    function disableSwipeBack() {
        // Optional leer lassen.
        // Falls du das später brauchst, kannst du im NavigationController
        // eine property swipeBackEnabled ergänzen.
    }
}
