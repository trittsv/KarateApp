// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

AppToolBar {
    id: seminarToolbar

    property bool showListView: false
    property bool seminarsLoading: false
    property bool geocodingRunning: false
    property int geocodeDone: 0
    property int geocodeTotal: 0
    property bool hasUserPosition: false
    property bool locationPermissionGranted: false
    property bool sortByDistance: false
    property bool radiusFilterEnabled: true
    property real radiusKm: 100
    property var eventTypeFilters: []
    readonly property var allEventTypes: [
        "seminar",
        "competition",
        "national_team",
        "regional_team",
        "training"
    ]

    signal toggleViewRequested()
    signal locationRequested()
    signal sortByDistanceRequested(bool enabled)
    signal eventTypeFiltersRequested(var filters)
    signal radiusFilterEnabledRequested(bool enabled)
    signal radiusDecreaseRequested()
    signal radiusIncreaseRequested()

    function isEventTypeSelected(eventType) {
        return eventTypeFilters.indexOf(eventType) !== -1
    }

    function toggleEventType(eventType, selected) {
        let filters = eventTypeFilters.slice()
        const index = filters.indexOf(eventType)

        if (selected && index === -1)
            filters.push(eventType)
        else if (!selected && index !== -1)
            filters.splice(index, 1)

        eventTypeFiltersRequested(filters)
    }

    function syncFilterMenuChecks() {
        allEventTypesItem.checked = eventTypeFilters.length === allEventTypes.length
        seminarEventTypeItem.checked = isEventTypeSelected("seminar")
        competitionEventTypeItem.checked = isEventTypeSelected("competition")
        nationalTeamEventTypeItem.checked = isEventTypeSelected("national_team")
        regionalTeamEventTypeItem.checked = isEventTypeSelected("regional_team")
        trainingEventTypeItem.checked = isEventTypeSelected("training")
    }

    onEventTypeFiltersChanged: syncFilterMenuChecks()

    RowLayout {
        anchors.fill: parent

        Image {
            source: "qrc:/KarateApp/res/apple/iOS/iPhone_180.png"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Label {
                text: "KarateApp"
                font.bold: true
                Layout.fillWidth: true
            }

            Item {
                id: seminarSourceLink

                implicitHeight: 10
                Layout.fillWidth: true

                Accessible.role: Accessible.Link
                Accessible.name: "Quelle der Termine öffnen: DJKB"
                Accessible.onPressAction:
                    Qt.openUrlExternally("https://www.djkb.com/termine/")

                Label {
                    anchors.fill: parent
                    text: "Termine - Quelle: DJKB"
                    font.pixelSize: 8
                    font.underline: seminarSourceHover.hovered
                    color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                HoverHandler {
                    id: seminarSourceHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped:
                        Qt.openUrlExternally("https://www.djkb.com/termine/")
                }
            }
        }

        ToolButton {
            visible: !seminarToolbar.hasUserPosition
                     && !seminarToolbar.locationPermissionGranted
            text: "Standort aktivieren"
            font.pixelSize: 12
            Accessible.name: "Standort aktivieren"
            Layout.rightMargin: 8
            onClicked: seminarToolbar.locationRequested()
        }

        RowLayout {
            visible: seminarToolbar.seminarsLoading || seminarToolbar.geocodingRunning
            spacing: 6
            Layout.rightMargin: 8

            AppBusyIndicator {
                running: seminarToolbar.seminarsLoading
                         || seminarToolbar.geocodingRunning
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
            }

            Label {
                text: seminarToolbar.seminarsLoading
                      ? "Lade..."
                      : "Orte " + seminarToolbar.geocodeDone + "/" + seminarToolbar.geocodeTotal
                font.pixelSize: 12
                opacity: 0.75
            }

            ToolButton {
                visible: seminarToolbar.geocodingRunning
                text: "?"
                implicitWidth: 24
                implicitHeight: 24
                padding: 0
                onClicked: geocodeInfoPopup.open()

                background: Rectangle {
                    radius: width / 2
                    color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
                    border.color: Constants.borderColor(rootWindow.isDarkMode)
                    border.width: 1
                }
            }
        }

        Popup {
            id: geocodeInfoPopup
            x: Math.max(8, seminarToolbar.width - width - 8)
            y: seminarToolbar.height + 6
            width: Math.min(300, seminarToolbar.width - 16)
            modal: false
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            padding: 12

            background: Rectangle {
                radius: 14
                color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
                border.width: 1
            }

            contentItem: Label {
                text: "Die Orte werden bewusst langsam geladen. Der kostenlose Geocoding-Dienst erlaubt nur wenige Anfragen pro Sekunde, deshalb wird ungefähr ein Ort pro Sekunde aufgelöst. Bereits bekannte Orte werden zwischengespeichert."
                wrapMode: Text.WordWrap
                color: Constants.primaryTextColor(rootWindow.isDarkMode)
                font.pixelSize: 13
            }
        }

        ToolButton {
            id: sortButton
            text: "Sortieren"
            visible: seminarToolbar.showListView
            onClicked: sortMenu.open()

            Menu {
                id: sortMenu

                y: sortButton.height
                x: sortButton.x

                MenuItem {
                    id: distanceSortItem
                    text: "Nach Entfernung"
                    checkable: true
                    checked: seminarToolbar.sortByDistance
                    onTriggered: seminarToolbar.sortByDistanceRequested(true)
                }

                MenuItem {
                    id: dateSortItem
                    text: "Nach Datum"
                    checkable: true
                    checked: !seminarToolbar.sortByDistance
                    onTriggered: seminarToolbar.sortByDistanceRequested(false)
                }

                onAboutToShow: {
                    distanceSortItem.checked = seminarToolbar.sortByDistance
                    dateSortItem.checked = !seminarToolbar.sortByDistance
                }
            }
        }

        ToolButton {
            id: filterButton
            text: "Filter"
            onClicked: filterMenu.open()

            Menu {
                id: filterMenu

                y: filterButton.height
                x: seminarToolbar.width
                   - filterButton.mapToItem(seminarToolbar, 0, 0).x
                   - width
                popupType: Popup.Item
                onAboutToShow: seminarToolbar.syncFilterMenuChecks()

                MenuItem {
                    id: allEventTypesItem
                    text: "Alle Termine"
                    checkable: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            seminarToolbar.eventTypeFiltersRequested(
                                allEventTypesItem.checked
                                ? []
                                : seminarToolbar.allEventTypes.slice()
                            )
                        }
                    }
                }

                MenuItem {
                    id: seminarEventTypeItem
                    text: "Lehrgänge"
                    checkable: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: seminarToolbar.toggleEventType(
                            "seminar",
                            !seminarToolbar.isEventTypeSelected("seminar")
                        )
                    }
                }

                MenuItem {
                    id: competitionEventTypeItem
                    text: "Wettkämpfe"
                    checkable: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: seminarToolbar.toggleEventType(
                            "competition",
                            !seminarToolbar.isEventTypeSelected("competition")
                        )
                    }
                }

                MenuItem {
                    id: nationalTeamEventTypeItem
                    text: "Bundeskader"
                    checkable: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: seminarToolbar.toggleEventType(
                            "national_team",
                            !seminarToolbar.isEventTypeSelected("national_team")
                        )
                    }
                }

                MenuItem {
                    id: regionalTeamEventTypeItem
                    text: "Stützpunktkader"
                    checkable: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: seminarToolbar.toggleEventType(
                            "regional_team",
                            !seminarToolbar.isEventTypeSelected("regional_team")
                        )
                    }
                }

                MenuItem {
                    id: trainingEventTypeItem
                    text: "Ausbildungen"
                    checkable: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: seminarToolbar.toggleEventType(
                            "training",
                            !seminarToolbar.isEventTypeSelected("training")
                        )
                    }
                }

                MenuSeparator {}

                MenuItem {
                    id: radiusFilterItem
                    text: "Umkreis-Filter"
                    checkable: true
                    checked: seminarToolbar.radiusFilterEnabled
                    enabled: seminarToolbar.hasUserPosition

                    MouseArea {
                        anchors.fill: parent
                        onClicked: seminarToolbar.radiusFilterEnabledRequested(
                            !seminarToolbar.radiusFilterEnabled
                        )
                    }
                }

                MenuItem {
                    enabled: seminarToolbar.hasUserPosition
                    height: radiusFilterControls.implicitHeight + 18

                    contentItem: Row {
                        id: radiusFilterControls
                        spacing: 6
                        leftPadding: 14
                        rightPadding: 14

                        Rectangle {
                            readonly property bool controlEnabled: seminarToolbar.radiusFilterEnabled
                                                                   && seminarToolbar.radiusKm > 50

                            width: 38
                            height: 34
                            radius: 10
                            color: controlEnabled
                                   ? Constants.cardBackgroundColor(rootWindow.isDarkMode)
                                   : Constants.secondaryCardBackgroundColor(rootWindow.isDarkMode)
                            border.color: Constants.separatorColor(rootWindow.isDarkMode)

                            Label {
                                anchors.centerIn: parent
                                text: "-"
                                font.pixelSize: 18
                                font.bold: true
                                color: parent.controlEnabled
                                       ? Constants.primaryTextColor(rootWindow.isDarkMode)
                                       : Constants.tertiaryTextColor(rootWindow.isDarkMode)
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: parent.controlEnabled
                                onClicked: seminarToolbar.radiusDecreaseRequested()
                            }
                        }

                        Label {
                            width: 58
                            anchors.verticalCenter: parent.verticalCenter
                            text: seminarToolbar.radiusFilterEnabled
                                  ? Math.round(seminarToolbar.radiusKm) + " km"
                                  : "Alle"
                            color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            readonly property bool controlEnabled: seminarToolbar.radiusFilterEnabled

                            width: 38
                            height: 34
                            radius: 10
                            color: controlEnabled
                                   ? Constants.cardBackgroundColor(rootWindow.isDarkMode)
                                   : Constants.secondaryCardBackgroundColor(rootWindow.isDarkMode)
                            border.color: Constants.separatorColor(rootWindow.isDarkMode)

                            Label {
                                anchors.centerIn: parent
                                text: "+"
                                font.pixelSize: 18
                                font.bold: true
                                color: parent.controlEnabled
                                       ? Constants.primaryTextColor(rootWindow.isDarkMode)
                                       : Constants.tertiaryTextColor(rootWindow.isDarkMode)
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: parent.controlEnabled
                                onClicked: seminarToolbar.radiusIncreaseRequested()
                            }
                        }
                    }
                }
            }
        }

        ToolButton {
            text: seminarToolbar.showListView ? "Karte" : "Liste"
            onClicked: seminarToolbar.toggleViewRequested()
        }

        Item {
            Layout.preferredHeight: 1
            Layout.preferredWidth: 8
        }
    }
}
