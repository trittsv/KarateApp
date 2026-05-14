// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

Page {
    id: impressumView

    required property var mainContentStackView
    implicitWidth: 0
    implicitHeight: 0

    background: Rectangle {
        color: Constants.backgroundColor(rootWindow.isDarkMode)
    }

    header: AppToolBar {
        RowLayout {
            anchors.fill: parent

            ToolButton {
                id: backButton
                text: "‹ Zurück"
                onClicked: mainContentView.popMainContent()
            }

            Label {
                text: "Impressum"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                Layout.rightMargin: backButton.implicitWidth
            }
        }
    }

    ScrollView {
        id: imprintScrollView
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        contentWidth: availableWidth

        ColumnLayout {
            width: imprintScrollView.availableWidth
            spacing: 16

            Item {
                Layout.preferredHeight: 5
                Layout.fillWidth: true
            }

            InfoCard {
                title: "App-Anbieter"
                body: "Sven Trittler\nE-Mail: karateapp@gmx.de"
            }

            InfoCard {
                title: "Hinweis"
                body: "Diese App ist ein privates Projekt und dient der übersichtlichen Darstellung öffentlich verfügbarer Informationen rund um den Karatesport."
            }

            InfoCard {
                title: "Haftungsausschluss"
                body: "Die Inhalte dieser App wurden mit größter Sorgfalt erstellt. Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte kann jedoch keine Gewähr übernommen werden."
            }

            InfoCard {
                title: "Datenquelle"
                body: "Die in dieser App angezeigten Inhalte und Daten stammen hauptsächlich aus öffentlich zugänglichen Bereichen der Webseite des Deutschen JKA-Karate Bundes (DJKB), darunter beispielsweise Termine, Nachrichten, Wettkampfergebnisse, Dojo-Informationen und Bilder:\n\n"
                 + "https://www.djkb.com/\n\n"
                 + "Die Inhalte werden automatisiert abgerufen und für die Darstellung in der App aufbereitet. Maßgeblich sind stets die Informationen auf der Webseite des DJKB.\n\n"
                 + "Diese Anwendung ist ein unabhängiges Projekt und steht in keiner offiziellen Verbindung zum DJKB, sofern nicht ausdrücklich anders angegeben."
            }

            InfoCard {
                title: "Externe Links"
                body: "Diese App enthält Links zu externen Webseiten. Für deren Inhalte sind ausschließlich die jeweiligen Betreiber verantwortlich."
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
}
