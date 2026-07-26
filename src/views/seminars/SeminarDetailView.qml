// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: seminarDetailView

    required property var mainContentStackView
    required property string titleText
    required property string dateText
    required property string categoryText
    required property string dojoText
    required property string contactText
    required property string emailText
    required property string phoneText
    required property string streetText
    required property string zipText
    required property string cityText
    required property string distanceTextValue
    property string eventTypeLabelText: "Lehrgang"
    required property string pdfUrl
    required property string icsUrl
    required property string mapsUrl

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    header: AppToolBar {
        Item {
            anchors.fill: parent

            ToolButton {
                text: "‹ Zurück"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: seminarDetailView.eventTypeLabelText
                font.bold: true
                anchors.centerIn: parent
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: seminarDetailView.width
            spacing: 14

            Label {
                text: titleText
                font.pixelSize: 26
                font.bold: true
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.topMargin: 24
            }

            Label {
                text: eventTypeLabelText + " \u00B7 " + dateText + (distanceTextValue ? " \u00B7 " + distanceTextValue : "")
                font.pixelSize: 14
                opacity: 0.65
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
            }

            InfoCard {
                title: "Kategorie"
                body: categoryText
                visible: categoryText !== ""
            }

            InfoCard {
                title: "Ausrichter / Ansprechpartner"
                body: [
                    dojoText,
                    contactText,
                    emailText ? "E-Mail: " + emailText : "",
                    phoneText ? "Telefon: " + phoneText : ""
                ].filter(function(v) { return v !== "" }).join("\n")
                visible: body !== ""
            }

            InfoCard {
                title: "Ort"
                body: "Straße: " + streetText + "\nPLZ / Ort: " + zipText + " " + cityText
            }

            Label {
                text: "Bitte Veranstaltungsort und Details in der offiziellen Ausschreibung prüfen."
                font.pixelSize: 12
                font.italic: true
                opacity: 0.6
                wrapMode: Text.WordWrap

                Layout.fillWidth: true
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Layout.topMargin: -6
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                implicitHeight: actionColumn.implicitHeight + 28
                radius: 14
                color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
                border.color: Constants.borderColor(rootWindow.isDarkMode)

                ColumnLayout {
                    id: actionColumn
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Label {
                        text: "Aktionen"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    ActionRow {
                        enabled: pdfUrl !== ""
                        text: enabled
                              ? "Ausschreibung anzeigen"
                              : "Keine Ausschreibung vorhanden"
                        onClicked: {
                            pushMainContent("qrc:/KarateApp/src/views/seminars/SeminarPdfView.qml", {
                                pdfUrl: pdfUrl,
                                titleText: "Ausschreibung"
                            })
                        }
                    }

                    ActionRow {
                        visible: icsUrl !== ""
                        text: "In den Kalender übernehmen"
                        onClicked: Qt.openUrlExternally(icsUrl)
                    }

                    ActionRow {
                        visible: mapsUrl !== ""
                        text: "In Google Maps öffnen"
                        onClicked: Qt.openUrlExternally(mapsUrl)
                    }
                }
            }

            SourceAttribution {
                sourceName: "Termininformationen beim DJKB"
                sourceUrl: pdfUrl !== ""
                           ? pdfUrl
                           : "https://www.djkb.com/termine/"
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
            }

            Item {
                Layout.preferredHeight: 24
            }
        }
    }

    component InfoCard: Rectangle {
        property alias title: titleLabel.text
        property alias body: bodyLabel.text

        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16

        implicitHeight: contentColumn.implicitHeight + 28
        radius: 14

        color: Constants.cardBackgroundColor(rootWindow.isDarkMode)
        border.color: Constants.borderColor(rootWindow.isDarkMode)

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Label {
                id: titleLabel
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            Label {
                id: bodyLabel
                font.pixelSize: 14
                opacity: 0.75
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }

    component ActionRow: Rectangle {
        id: actionRow

        signal clicked()
        property alias text: actionLabel.text
        property bool pressed: false

        Layout.fillWidth: true
        height: 48
        radius: 10
        opacity: enabled ? 1.0 : 0.5

        color: pressed && enabled
               ? Constants.pressedColor(rootWindow.isDarkMode)
               : Constants.secondaryCardBackgroundColor(rootWindow.isDarkMode)

        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Label {
                id: actionLabel
                font.pixelSize: 15
                Layout.fillWidth: true
            }

            Label {
                text: "›"
                visible: actionRow.enabled
                font.pixelSize: 24
                color: Constants.chevronColor(rootWindow.isDarkMode)
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: actionRow.enabled
            onPressed: actionRow.pressed = true
            onReleased: actionRow.pressed = false
            onCanceled: actionRow.pressed = false
            onClicked: actionRow.clicked()
        }
    }
}
