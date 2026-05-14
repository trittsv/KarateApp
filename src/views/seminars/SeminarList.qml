// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

ListView {
    id: seminarListView

    property alias seminarModel: seminarListView.model

    signal seminarClicked(var seminar)

    clip: true
    boundsBehavior: Flickable.DragAndOvershootBounds
    topMargin: 8
    bottomMargin: rootWindow.isDesktop
                  ? 8
                  : Math.max(72, rootWindow.SafeArea.margins.bottom + 64)
    leftMargin: 8
    rightMargin: 8
    spacing: 8

    delegate: ItemDelegate {
        id: listItem

        required property int seminarId
        required property string title
        required property string date
        required property string category
        required property string dojo
        required property string contact
        required property string email
        required property string phone
        required property string street
        required property string zip
        required property string city
        required property string distanceText
        required property string eventType
        required property string eventTypeLabel
        required property string pdf_url
        required property string ics_url
        required property string maps_url
        required property bool isOutdated

        width: seminarListView.width - seminarListView.leftMargin - seminarListView.rightMargin
        height: 128 + (listItem.isOutdated ? 34 : 0)
        leftPadding: 14
        rightPadding: 12
        topPadding: 10
        bottomPadding: 10

        background: Rectangle {
            radius: 14
            color: listItem.down
                   ? Constants.pressedColor(rootWindow.isDarkMode)
                   : Constants.cardBackgroundColor(rootWindow.isDarkMode)
            border.color: listItem.isOutdated
                          ? Constants.destructiveColor
                          : Constants.borderColor(rootWindow.isDarkMode)
            border.width: listItem.isOutdated ? 2 : 1
        }

        contentItem: ColumnLayout {
            spacing: 8

            Rectangle {
                visible: listItem.isOutdated
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                radius: 8
                color: Constants.destructiveColor

                Label {
                    anchors.centerIn: parent
                    text: "VERGANGEN"
                    font.pixelSize: 12
                    font.bold: true
                    color: "white"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        id: titleListItem
                        text: listItem.title
                        font.bold: true
                        font.pixelSize: 16
                        color: Constants.primaryTextColor(rootWindow.isDarkMode)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: listItem.date
                            font.pixelSize: 13
                            font.bold: true
                            color: listItem.isOutdated
                                   ? Constants.destructiveColor
                                   : Constants.secondaryTextColor(
                                         rootWindow.isDarkMode)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            visible: !listItem.isOutdated
                                     && listItem.distanceText !== ""
                            radius: 8
                            color: Constants.successBadgeBackgroundColor(rootWindow.isDarkMode)
                            border.color: Constants.successBadgeBorderColor(rootWindow.isDarkMode)
                            implicitWidth: distanceLabel.implicitWidth + 14
                            implicitHeight: 22

                            Label {
                                id: distanceLabel
                                anchors.centerIn: parent
                                text: listItem.distanceText
                                font.pixelSize: 12
                                color: Constants.successBadgeTextColor(rootWindow.isDarkMode)
                            }
                        }

                        Rectangle {
                            visible: !listItem.isOutdated
                                     && listItem.distanceText === ""
                            radius: 8
                            color: Constants.warningBadgeBackgroundColor(rootWindow.isDarkMode)
                            border.color: Constants.warningBadgeBorderColor(rootWindow.isDarkMode)
                            implicitWidth: unknownDistanceLabel.implicitWidth + 14
                            implicitHeight: 22

                            Label {
                                id: unknownDistanceLabel
                                anchors.centerIn: parent
                                text: "Entfernung unbekannt"
                                font.pixelSize: 12
                                color: Constants.destructiveColor
                            }
                        }
                    }

                    Label {
                        text: listItem.city + (listItem.dojo ? " \u00B7 " + listItem.dojo : "")
                        font.pixelSize: 13
                        color: Constants.secondaryTextColor(rootWindow.isDarkMode)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Label {
                        text: listItem.eventTypeLabel + (listItem.category ? " \u00B7 " + listItem.category : "")
                        font.pixelSize: 12
                        color: Constants.tertiaryTextColor(rootWindow.isDarkMode)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Label {
                    text: "\u203A"
                    font.pixelSize: 26
                    color: Constants.chevronColor(rootWindow.isDarkMode)
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 18
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        onClicked: seminarListView.seminarClicked({
            seminarId: listItem.seminarId,
            title: listItem.title,
            date: listItem.date,
            category: listItem.category,
            eventType: listItem.eventType,
            eventTypeLabel: listItem.eventTypeLabel,
            dojo: listItem.dojo,
            contact: listItem.contact,
            email: listItem.email,
            phone: listItem.phone,
            street: listItem.street,
            zip: listItem.zip,
            city: listItem.city,
            distanceText: listItem.distanceText,
            isOutdated: listItem.isOutdated,
            pdf_url: listItem.pdf_url,
            ics_url: listItem.ics_url,
            maps_url: listItem.maps_url
        })
    }
}
