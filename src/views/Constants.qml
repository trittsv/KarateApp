// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

pragma Singleton

import QtCore
import QtQuick

Item {
    property int tabBarIconSize: 20

    property color lightBackgroundColor: "#F2F2F7"
    property color lightSafeEdgeColor: "#FFFFFF"
    property color lightCardBackgroundColor: "#ffffff"
    property color lightSecondaryCardBackgroundColor: "#F7F7FA"
    property color lightPressedColor: "#E9E9EF"
    property color lightBorderColor: "#E1E1E6"
    property color lightSeparatorColor: "#ECECF0"
    property color lightPrimaryTextColor: "#111111"
    property color lightSecondaryTextColor: "#5F6368"
    property color lightTertiaryTextColor: "#777D85"
    property color lightChevronColor: "#A0A0A6"

    property color darkBackgroundColor: "#1F1F22"
    property color darkSafeEdgeColor: "#171719"
    property color darkCardBackgroundColor: "#2A2A2D"
    property color darkSecondaryCardBackgroundColor: "#242427"
    property color darkPressedColor: "#36363A"
    property color darkBorderColor: "#3A3A3E"
    property color darkSeparatorColor: "#333338"
    property color darkPrimaryTextColor: "#F5F5F7"
    property color darkSecondaryTextColor: "#C7C7CC"
    property color darkTertiaryTextColor: "#9A9AA0"
    property color darkChevronColor: "#7A7A80"

    property color accentColor: "#D70015"
    property color destructiveColor: "#E53935"
    property color locationMarkerColor: "#0A84FF"

    property color lightSuccessBadgeBackgroundColor: "#EAF6EE"
    property color lightSuccessBadgeBorderColor: "#C8E6D0"
    property color lightSuccessBadgeTextColor: "#2F6F3E"
    property color darkSuccessBadgeBackgroundColor: "#203A2C"
    property color darkSuccessBadgeBorderColor: "#365B45"
    property color darkSuccessBadgeTextColor: "#BDE5C9"

    property color lightWarningBadgeBackgroundColor: "#FCECEC"
    property color lightWarningBadgeBorderColor: "#F4C7C7"
    property color darkWarningBadgeBackgroundColor: "#3A2424"
    property color darkWarningBadgeBorderColor: "#5B3636"

    property int toolbarPadding: 10

    function backgroundColor(isDarkMode) {
        return isDarkMode ? darkBackgroundColor : lightBackgroundColor
    }

    function safeEdgeColor(isDarkMode) {
        return isDarkMode ? darkSafeEdgeColor : lightSafeEdgeColor
    }

    function cardBackgroundColor(isDarkMode) {
        return isDarkMode ? darkCardBackgroundColor : lightCardBackgroundColor
    }

    function secondaryCardBackgroundColor(isDarkMode) {
        return isDarkMode ? darkSecondaryCardBackgroundColor : lightSecondaryCardBackgroundColor
    }

    function pressedColor(isDarkMode) {
        return isDarkMode ? darkPressedColor : lightPressedColor
    }

    function borderColor(isDarkMode) {
        return isDarkMode ? darkBorderColor : lightBorderColor
    }

    function separatorColor(isDarkMode) {
        return isDarkMode ? darkSeparatorColor : lightSeparatorColor
    }

    function primaryTextColor(isDarkMode) {
        return isDarkMode ? darkPrimaryTextColor : lightPrimaryTextColor
    }

    function secondaryTextColor(isDarkMode) {
        return isDarkMode ? darkSecondaryTextColor : lightSecondaryTextColor
    }

    function tertiaryTextColor(isDarkMode) {
        return isDarkMode ? darkTertiaryTextColor : lightTertiaryTextColor
    }

    function chevronColor(isDarkMode) {
        return isDarkMode ? darkChevronColor : lightChevronColor
    }

    function successBadgeBackgroundColor(isDarkMode) {
        return isDarkMode ? darkSuccessBadgeBackgroundColor : lightSuccessBadgeBackgroundColor
    }

    function successBadgeBorderColor(isDarkMode) {
        return isDarkMode ? darkSuccessBadgeBorderColor : lightSuccessBadgeBorderColor
    }

    function successBadgeTextColor(isDarkMode) {
        return isDarkMode ? darkSuccessBadgeTextColor : lightSuccessBadgeTextColor
    }

    function warningBadgeBackgroundColor(isDarkMode) {
        return isDarkMode ? darkWarningBadgeBackgroundColor : lightWarningBadgeBackgroundColor
    }

    function warningBadgeBorderColor(isDarkMode) {
        return isDarkMode ? darkWarningBadgeBorderColor : lightWarningBadgeBorderColor
    }

    /// @brief Bytes to Gigabytes (not Gibibytes!)
    function formatBytes(bytes) {
        const kilobyte = 1000;
        const megabyte = kilobyte * 1000;
        const gigabyte = megabyte * 1000;

        if (bytes < kilobyte) {
            return bytes + " B";
        } else if (bytes < megabyte) {
            return (bytes / kilobyte).toFixed(1) + " KB";
        } else if (bytes < gigabyte) {
            return (bytes / megabyte).toFixed(1) + " MB";
        } else {
            return (bytes / gigabyte).toFixed(1) + " GB";
        }
    }
}
