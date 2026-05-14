// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts
import QtLocation
import QtPositioning

import ".."

Item {
    id: seminarViewId

    Layout.fillWidth: true
    Layout.fillHeight: true

    property var selectedMarker: null
    property bool showListView: false

    property int selectedSeminarId: -1
    property var selectedSeminar: ({})

    property bool seminarsLoading: seminarModel.count === 0
    property bool hasUserPosition: posSource.position.coordinate.isValid
    property bool sortByDistance: false
    property bool radiusFilterEnabled: seminarSettings.radiusFilterEnabled
    property real mapRadiusKm: seminarSettings.mapRadiusKm
    property bool hasMarkerRebuildCoordinate: false
    property var lastMarkerRebuildCoordinate: QtPositioning.coordinate(0, 0)
    property bool seminarGeocodeRunning: false
    property int seminarGeocodeDone: 0
    property int seminarGeocodeTotal: 0
    property var pendingSeminarGeocodes: []
    property var requestedSeminarGeocodes: ({})
    property var eventTypeFilters: [
        "seminar",
        "competition",
        "national_team",
        "regional_team",
        "training"
    ]

    Component.onCompleted: {
        checkAndStartLocation()
        seminarProxyModel.maxDistanceKm =
                radiusFilterEnabled && hasUserPosition ? mapRadiusKm : -1

        if (seminarModel.count > 0)
            rebuildSeminarMarkers()
        queueMissingSeminarCoordinates()
    }

    Component {
        id: markerComponent

        SeminarMarker {
            seminar: ({})
            seminarId: -1
            selected: seminarViewId.selectedSeminarId === seminarId

            onClicked: function(markerItem) {
                if (seminarViewId.selectedSeminarId === markerItem.seminarId) {
                    seminarViewId.clearSelectedSeminar()
                    return
                }

                seminarViewId.selectedMarker = markerItem
                seminarViewId.showSelectedSeminar(markerItem.seminar)
            }
        }
    }

    function showSelectedSeminar(item) {
        console.log("Selected seminar:", item.seminarId, item.title)

        selectedSeminarId = item.seminarId
        selectedSeminar = item
    }

    function clearSelectedSeminar() {
        selectedSeminarId = -1
        selectedSeminar = ({})
        selectedMarker = null
    }

    function currentSeminarItem(item) {
        if (!item || item.seminarId === undefined)
            return item

        let fresh = seminarModel.getById(item.seminarId)

        if (fresh && fresh.seminarId !== undefined)
            return fresh

        return item
    }

    function openSeminarDetails(item) {
        item = currentSeminarItem(item)

        pushMainContent("qrc:/KarateApp/src/views/seminars/SeminarDetailView.qml", {
            titleText: item.title,
            dateText: item.date,
            categoryText: item.category,
            dojoText: item.dojo,
            contactText: item.contact,
            emailText: item.email,
            phoneText: item.phone,
            streetText: item.street,
            zipText: item.zip,
            cityText: item.city,
            distanceTextValue: item.distanceText,
            eventTypeLabelText: item.eventTypeLabel,
            pdfUrl: item.pdf_url,
            icsUrl: item.ics_url,
            mapsUrl: item.maps_url
        })
    }

    function addMarkerForSeminar(item, coord) {
        if (item.isOutdated)
            return

        let marker = markerComponent.createObject(null, {
            coordinate: coord,
            seminar: item,
            seminarId: item.seminarId,
            eventType: item.eventType,
            eventTypeFilters: Qt.binding(function() { return seminarViewId.eventTypeFilters })
        })

        if (marker) {
            seminarMap.addMarker(marker)
            console.debug("Marker added")
        }
    }

    function coordinateInMapRadius(coord) {
        if (!radiusFilterEnabled || !hasUserPosition || !posSource.position.coordinate.isValid)
            return true

        return posSource.position.coordinate.distanceTo(coord) / 1000
                <= mapRadiusKm
    }

    function radiusStep() {
        return 50
    }

    function setMapRadiusKm(value) {
        mapRadiusKm = Math.max(50, Math.round(value / 50) * 50)
        seminarSettings.mapRadiusKm = mapRadiusKm
        seminarProxyModel.maxDistanceKm =
                radiusFilterEnabled && hasUserPosition ? mapRadiusKm : -1
        rebuildSeminarMarkers()
    }

    function setRadiusFilterEnabled(enabled) {
        radiusFilterEnabled = enabled
        seminarSettings.radiusFilterEnabled = enabled
        seminarProxyModel.maxDistanceKm =
                radiusFilterEnabled && hasUserPosition ? mapRadiusKm : -1
        rebuildSeminarMarkers()
    }

    function shouldRebuildMarkersForPosition(coord) {
        if (!radiusFilterEnabled)
            return false

        if (!hasMarkerRebuildCoordinate)
            return true

        return lastMarkerRebuildCoordinate.distanceTo(coord) >= 1000
    }

    function checkAndStartLocation() {
        console.log("checkAndStartLocation", locPermission.status)

        if (locPermission.status === Qt.PermissionStatus.Granted) {
            posSource.active = true
            posSource.start()
        } else if (locPermission.status === Qt.PermissionStatus.Undetermined) {
            console.log("Request permission")
            locPermission.request()
        } else {
            console.warn("Standortzugriff wurde vom Nutzer blockiert!")
        }
    }

    function rebuildSeminarMarkers() {
        seminarsLoading = false
        clearSelectedSeminar()
        seminarMap.clearSeminarMarkers()

        for (let i = 0; i < seminarModel.count; i++) {
            const seminar = seminarModel.get(i)
            if (!seminar.hasCoordinate || seminar.isOutdated)
                continue

            const coord = QtPositioning.coordinate(seminar.latitude, seminar.longitude)
            if (coord && coord.isValid && coordinateInMapRadius(coord))
                addMarkerForSeminar(seminar, coord)
        }

        if (hasUserPosition && posSource.position.coordinate.isValid) {
            lastMarkerRebuildCoordinate = posSource.position.coordinate
            hasMarkerRebuildCoordinate = true
        }
    }

    function seminarGeocodeQuery(seminar) {
        const zipCity = [seminar.zip, seminar.city]
            .filter(function(value) { return value !== undefined && value !== "" })
            .join(" ")

        return [seminar.street, zipCity]
            .filter(function(value) { return value !== undefined && value !== "" })
            .join(", ")
    }

    function seminarGeocodeFallbackQuery(seminar) {
        return [seminar.zip, seminar.city]
            .filter(function(value) { return value !== undefined && value !== "" })
            .join(" ")
    }

    function queueMissingSeminarCoordinates() {
        let requested = requestedSeminarGeocodes
        let pending = pendingSeminarGeocodes.slice()

        for (let i = 0; i < seminarModel.count; i++) {
            const seminar = seminarModel.get(i)
            if (seminar.hasCoordinate || seminar.isOutdated || requested[seminar.seminarId])
                continue

            const query = seminarGeocodeQuery(seminar)
            if (query === "")
                continue

            requested[seminar.seminarId] = true
            pending.push({
                id: seminar.seminarId,
                query: query,
                fallbackQuery: seminarGeocodeFallbackQuery(seminar)
            })
        }

        requestedSeminarGeocodes = requested
        pendingSeminarGeocodes = pending
        seminarGeocodeTotal = Math.max(seminarGeocodeTotal, seminarGeocodeDone + pendingSeminarGeocodes.length + (seminarGeocodeRunning ? 1 : 0))
        processNextSeminarGeocode()
    }

    function processNextSeminarGeocode() {
        if (seminarGeocodeRunning || pendingSeminarGeocodes.length === 0)
            return

        let pending = pendingSeminarGeocodes.slice()
        const next = pending.shift()
        pendingSeminarGeocodes = pending
        seminarGeocodeRunning = true
        backendApiClient.geocodeLocation("seminar:" + next.id, next.query, next.fallbackQuery)
    }

    function addMarkerForUpdatedSeminar(seminarId) {
        if (!seminarMap || showListView)
            return

        const seminar = seminarModel.getById(seminarId)
        if (!seminar || !seminar.hasCoordinate || seminar.isOutdated)
            return

        const coord = QtPositioning.coordinate(seminar.latitude, seminar.longitude)
        if (coord && coord.isValid && coordinateInMapRadius(coord))
            addMarkerForSeminar(seminar, coord)
    }

    Connections {
        target: seminarModel

        function onCountChanged() {
            seminarViewId.seminarGeocodeRunning = false
            seminarViewId.seminarGeocodeDone = 0
            seminarViewId.seminarGeocodeTotal = 0
            seminarViewId.pendingSeminarGeocodes = []
            seminarViewId.requestedSeminarGeocodes = ({})
            rebuildSeminarMarkers()
            seminarViewId.queueMissingSeminarCoordinates()
        }
    }

    Connections {
        target: backendApiClient

        function onLocationGeocoded(requestId, latitude, longitude, found) {
            if (!requestId.startsWith("seminar:"))
                return

            seminarViewId.seminarGeocodeRunning = false
            seminarViewId.seminarGeocodeDone += 1
            if (found) {
                const seminarId = Number(requestId.substring(8))
                seminarModel.updateCoordinate(seminarId, latitude, longitude)
                seminarViewId.addMarkerForUpdatedSeminar(seminarId)
            }
            seminarViewId.processNextSeminarGeocode()
        }

        function onLocationGeocodeFailed(requestId, error) {
            if (!requestId.startsWith("seminar:"))
                return

            console.warn("Seminar geocode failed:", requestId, error)
            seminarViewId.seminarGeocodeRunning = false
            seminarViewId.seminarGeocodeDone += 1
            seminarViewId.processNextSeminarGeocode()
        }
    }

    Settings {
        id: seminarSettings
        category: "SeminarView"
        property bool radiusFilterEnabled: false
        property real mapRadiusKm: 100
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        SeminarToolbar {
            Layout.fillWidth: true
            showListView: seminarViewId.showListView
            seminarsLoading: seminarViewId.seminarsLoading
            geocodingRunning: seminarViewId.seminarGeocodeRunning
                              || seminarViewId.pendingSeminarGeocodes.length > 0
            geocodeDone: seminarViewId.seminarGeocodeDone
            geocodeTotal: seminarViewId.seminarGeocodeTotal
            hasUserPosition: seminarViewId.hasUserPosition
            locationPermissionGranted: locPermission.status === Qt.PermissionStatus.Granted
            sortByDistance: seminarViewId.sortByDistance
            radiusFilterEnabled: seminarViewId.radiusFilterEnabled
            radiusKm: seminarViewId.mapRadiusKm
            eventTypeFilters: seminarViewId.eventTypeFilters
            onToggleViewRequested: {
                seminarViewId.showListView = !seminarViewId.showListView
                if (!seminarViewId.showListView)
                    seminarViewId.rebuildSeminarMarkers()
            }
            onSortByDistanceRequested: function(enabled) {
                seminarViewId.sortByDistance = enabled
                seminarProxyModel.sortByDistance = enabled
            }
            onEventTypeFiltersRequested: function(filters) {
                seminarViewId.eventTypeFilters = filters
                seminarProxyModel.eventTypeFilters = filters
                seminarViewId.clearSelectedSeminar()
            }
            onRadiusFilterEnabledRequested: function(enabled) {
                seminarViewId.setRadiusFilterEnabled(enabled)
            }
            onRadiusDecreaseRequested: seminarViewId.setMapRadiusKm(
                seminarViewId.mapRadiusKm - seminarViewId.radiusStep()
            )
            onRadiusIncreaseRequested: seminarViewId.setMapRadiusKm(
                seminarViewId.mapRadiusKm + seminarViewId.radiusStep()
            )
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: seminarViewId.showListView ? 1 : 0

            SeminarMap {
                id: seminarMap
                Layout.fillWidth: true
                Layout.fillHeight: true
                plugin: mapPlugin
                selectedMarker: seminarViewId.selectedMarker
                selectedSeminarId: seminarViewId.selectedSeminarId
                selectedSeminar: seminarViewId.selectedSeminar
                hasUserPosition: seminarViewId.hasUserPosition
                userCoordinate: posSource.position.coordinate
                radiusKm: seminarViewId.radiusFilterEnabled
                          ? seminarViewId.mapRadiusKm : -1
                onRadiusFilterToggleRequested: {
                    seminarViewId.setRadiusFilterEnabled(
                        !seminarViewId.radiusFilterEnabled
                    )
                }
                onSelectedSeminarOpenRequested: function(seminar) {
                    seminarViewId.openSeminarDetails(seminar)
                }
            }

            SeminarList {
                id: seminarList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: seminarProxyModel
                onSeminarClicked: function(seminar) {
                    seminarViewId.openSeminarDetails(seminar)
                }
            }
        }
    }

    PositionSource {
        id: posSource
        active: false
        updateInterval: 1000

        onPositionChanged: {
            let coord = position.coordinate

            if (coord && coord.isValid) {
                seminarModel.updateUserPosition(coord.latitude, coord.longitude)
                seminarProxyModel.maxDistanceKm =
                        seminarViewId.radiusFilterEnabled
                        ? seminarViewId.mapRadiusKm : -1

                if (seminarViewId.shouldRebuildMarkersForPosition(coord))
                    seminarViewId.rebuildSeminarMarkers()
            }
        }

        onSourceErrorChanged: {
            if (sourceError === PositionSource.AccessError) {
                console.log("Location error: AccessError", sourceError)
            } else if (sourceError === PositionSource.ClosedError) {
                console.log("Location error: ClosedError", sourceError)
            } else if (sourceError === PositionSource.NoError) {
                console.log("Location error: NoError", sourceError)
            } else if (sourceError === PositionSource.UnknownSourceError) {
                console.log("Location error: UnknownSourceError", sourceError)
            } else if (sourceError === PositionSource.UpdateTimeoutError) {
                console.log("Location error: UpdateTimeoutError", sourceError)
            } else {
                console.log("Unknown position error: ", sourceError)
            }
        }
    }

    LocationPermission {
        id: locPermission
    }

    Connections {
        target: locPermission

        function onStatusChanged() {
            console.log("locPermission onStatusChanged", locPermission.status)

            if (locPermission.status === Qt.PermissionStatus.Granted) {
                console.log("Erlaubnis erteilt! Starte GPS...")
                posSource.active = true
            } else if (locPermission.status === Qt.PermissionStatus.Denied) {
                console.warn("Erlaubnis verweigert.")
            }
        }
    }
}
