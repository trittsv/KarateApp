// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

import ".."

Page {
    id: dojoView

    required property var mainContentStackView
    property bool showBackButton: false
    property bool showMap: false
    property bool mapInitialized: false
    property bool dojoGeocodeRunning: false
    property var pendingDojoGeocodes: []
    property var requestedDojoGeocodes: ({})

    function resetSearch() {
        dojoProxyModel.searchText = ""
        dojoSearchField.text = ""
    }

    function openDojoDetails(dojo) {
        pushMainContent(
            "qrc:/KarateApp/src/views/dojos/DojoDetailView.qml",
            {
                titleText: dojo.title,
                streetText: dojo.street,
                zipCityText: dojo.zipCity,
                websiteUrl: dojo.website,
                emailText: dojo.email,
                phoneText: dojo.phone,
                contactText: dojo.contact,
                notesText: dojo.notes,
                imageUrl: dojo.imageUrl
            }
        )
    }

    function startMapGeocoding() {
        if (mapInitialized)
            return

        mapInitialized = true
    }

    function toggleView() {
        showMap = !showMap
        if (showMap)
            startMapGeocoding()
    }

    function loadDojosIfNeeded() {
        if (dojoModel.count === 0 && !backendApiClient.dojoLoading)
            backendApiClient.loadDojos()
    }

    function dojoGeocodeQuery(dojo) {
        return [dojo.street, dojo.zipCity]
            .filter(function(value) { return value !== undefined && value !== "" })
            .join(", ")
    }

    function dojoGeocodeFallbackQuery(dojo) {
        return dojo.zipCity || ""
    }

    function queueMissingDojoCoordinates() {
        let requested = requestedDojoGeocodes
        let pending = pendingDojoGeocodes.slice()

        for (let i = 0; i < dojoModel.count; i++) {
            const dojo = dojoModel.get(i)
            if (dojo.hasCoordinate || requested[dojo.dojoId])
                continue

            const query = dojoGeocodeQuery(dojo)
            if (query === "")
                continue

            requested[dojo.dojoId] = true
            pending.push({
                id: dojo.dojoId,
                query: query,
                fallbackQuery: dojoGeocodeFallbackQuery(dojo)
            })
        }

        requestedDojoGeocodes = requested
        pendingDojoGeocodes = pending
        processNextDojoGeocode()
    }

    function processNextDojoGeocode() {
        if (dojoGeocodeRunning || pendingDojoGeocodes.length === 0)
            return

        let pending = pendingDojoGeocodes.slice()
        const next = pending.shift()
        pendingDojoGeocodes = pending
        dojoGeocodeRunning = true
        backendApiClient.geocodeLocation("dojo:" + next.id, next.query, next.fallbackQuery)
    }

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    Component.onCompleted: {
        console.log("DojoView onCompleted")
        resetSearch()
        loadDojosIfNeeded()
        queueMissingDojoCoordinates()
    }
    onVisibleChanged: if (visible) loadDojosIfNeeded()
    Component.onDestruction: dojoProxyModel.searchText = ""

    header: Column {
        width: parent.width

        AppToolBar {
            width: parent.width

            Item {
                anchors.fill: parent

                ToolButton {
                    visible: dojoView.showBackButton
                    text: "\u2039 Zurück"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: mainContentView.popMainContent()
                }

                Label {
                    text: "Dojos"
                    font.bold: true
                    anchors.centerIn: parent
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Label {
                        visible: dojoModel.count > 0 && dojoView.width >= 600
                        text: dojoModel.count + " Vereine"
                        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                    }

                    ToolButton {
                        text: dojoView.showMap ? "Liste" : "Karte"
                        onClicked: dojoView.toggleView()
                    }

                    AppBusyIndicator {
                        running: backendApiClient.dojoLoading
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                    }
                }
            }
        }

        Pane {
            width: parent.width
            padding: 10
            visible: !dojoView.showMap

            TextField {
                id: dojoSearchField

                anchors.left: parent.left
                anchors.right: parent.right
                placeholderText: "Name, PLZ oder Ort suchen"
                onTextChanged: dojoProxyModel.searchText = text
            }
        }

    }

    Connections {
        target: dojoModel

        function onCountChanged() {
            dojoMap.selectedDojoId = -1
            dojoMap.selectedDojo = ({})
            dojoView.mapInitialized = false
            dojoView.dojoGeocodeRunning = false
            dojoView.pendingDojoGeocodes = []
            dojoView.requestedDojoGeocodes = ({})
            dojoView.queueMissingDojoCoordinates()

            if (dojoView.showMap)
                Qt.callLater(dojoView.startMapGeocoding)
        }
    }

    Connections {
        target: backendApiClient

        function onLocationGeocoded(requestId, latitude, longitude, found) {
            if (!requestId.startsWith("dojo:"))
                return

            dojoView.dojoGeocodeRunning = false
            if (found) {
                const dojoId = Number(requestId.substring(5))
                dojoModel.updateCoordinate(dojoId, latitude, longitude)
            }
            dojoView.processNextDojoGeocode()
        }

        function onLocationGeocodeFailed(requestId, error) {
            if (!requestId.startsWith("dojo:"))
                return

            console.warn("Dojo geocode failed:", requestId, error)
            dojoView.dojoGeocodeRunning = false
            dojoView.processNextDojoGeocode()
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: dojoView.showMap ? 1 : 0

        ListView {
            id: dojoList

            clip: true
            model: dojoProxyModel
            spacing: 10
            topMargin: 10
            bottomMargin: 14
            leftMargin: 10
            rightMargin: 10

            delegate: ItemDelegate {
                id: dojoItem

            required property string title
            required property string street
            required property string zipCity
            required property string website
            required property string email
            required property string phone
            required property string contact
            required property string notes
            required property string imageUrl

            width: dojoList.width - dojoList.leftMargin - dojoList.rightMargin
            height: dojoContent.implicitHeight + topPadding + bottomPadding
            leftPadding: 12
            rightPadding: 12
            topPadding: 12
            bottomPadding: 12

            background: Rectangle {
                radius: 14
                color: dojoItem.down
                       ? Constants.pressedColor(rootWindow.isDarkMode)
                       : Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)
                border.width: 1
            }

            contentItem: RowLayout {
                id: dojoContent
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 62
                    Layout.preferredHeight: 62
                    Layout.alignment: Qt.AlignTop
                    radius: 10
                    color: Constants.secondaryCardBackgroundColor(rootWindow.isDarkMode)
                    border.color: Constants.borderColor(rootWindow.isDarkMode)
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5
                        source: dojoItem.imageUrl
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: dojoItem.title
                        font.pixelSize: 16
                        font.bold: true
                        color: Constants.primaryTextColor(rootWindow.isDarkMode)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        text: [dojoItem.street, dojoItem.zipCity]
                              .filter(function(value) { return value !== "" })
                              .join("\n")
                        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        visible: dojoItem.contact !== ""
                        text: dojoItem.contact
                        font.pixelSize: 12
                        color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                Label {
                    text: "\u203A"
                    font.pixelSize: 26
                    color: Constants.chevronColor(rootWindow.isDarkMode)
                    Layout.alignment: Qt.AlignVCenter
                }
            }

                onClicked: dojoView.openDojoDetails({
                    title: dojoItem.title,
                    street: dojoItem.street,
                    zipCity: dojoItem.zipCity,
                    website: dojoItem.website,
                    email: dojoItem.email,
                    phone: dojoItem.phone,
                    contact: dojoItem.contact,
                    notes: dojoItem.notes,
                    imageUrl: dojoItem.imageUrl
                })
            }

            Label {
                anchors.centerIn: parent
                visible: !backendApiClient.dojoLoading && dojoList.count === 0
                text: backendApiClient.dojoErrorString !== ""
                      ? "Dojos konnten nicht geladen werden."
                      : dojoModel.count > 0
                        ? "Keine passenden Dojos gefunden"
                        : "Keine Dojos verfügbar"
                color: backendApiClient.dojoErrorString !== ""
                       ? Constants.destructiveColor
                       : Constants.secondaryTextColor(rootWindow.isDarkMode)
            }
        }

        DojoMap {
            id: dojoMap
            active: dojoView.showMap
            model: dojoModel
            plugin: mapPlugin
            onDojoOpenRequested: function(dojo) {
                dojoView.openDojoDetails(dojo)
            }
        }
    }
}
