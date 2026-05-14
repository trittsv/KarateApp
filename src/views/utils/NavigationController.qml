// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

import QtQuick

Item {
    id: nav

    property var stack: []
    property int edgeWidth: 32
    property real parallax: 0.28
    property bool dragging: false
    property bool transitionActive: false

    property bool swipeBackEnabled: Qt.platform.os !== "android"

    property real velocityPopThreshold: 900

    property int pushDuration: 240
    property int popDuration: 220
    property int cancelDuration: 420

    signal pagePushed(Item page)
    signal pagePopped(Item page)

    function canPop() {
        return stack.length > 1
    }

    function push(component, props) {
        if (!props)
            props = {}

        if (transitionActive)
            return

        var isFirstPage = stack.length === 0
        var page = component.createObject(pageLayer, props)

        page.width = nav.width
        page.height = nav.height
        page.x = isFirstPage ? 0 : nav.width
        page.y = 0
        page.z = stack.length
        page.enabled = true

        stack = stack.concat([page])
        updateVisibility()

        if (isFirstPage) {
            transitionActive = false
            page.x = 0
            updateVisibility()
            pagePushed(page)
            return
        }

        transitionActive = true

        pushAnim.targetItem = page
        pushAnim.fromValue = nav.width
        pushAnim.toValue = 0
        pushAnim.duration = nav.pushDuration
        pushAnim.start()

        pagePushed(page)
    }

    function pop() {
        if (stack.length <= 1 || transitionActive)
            return

        var page = stack[stack.length - 1]
        var previous = stack[stack.length - 2]

        transitionActive = true

        page.enabled = true
        previous.enabled = false
        previous.visible = true

        completePopAnim.targetItem = page
        completePopAnim.pageToDestroy = page
        completePopAnim.fromValue = page.x
        completePopAnim.toValue = nav.width
        completePopAnim.duration = nav.popDuration
        completePopAnim.start()

        previousAnim.targetItem = previous
        previousAnim.fromValue = previous.x
        previousAnim.toValue = 0
        previousAnim.duration = nav.popDuration
        previousAnim.start()
    }

    function updateVisibility() {
        for (var i = 0; i < stack.length; ++i) {
            var page = stack[i]

            page.width = nav.width
            page.height = nav.height
            page.z = i

            if (i === stack.length - 1) {
                page.visible = true
                page.enabled = true

                if (!dragging && !transitionActive)
                    page.x = 0
            } else if (i === stack.length - 2) {
                page.visible = true
                page.enabled = false

                if (!dragging && !transitionActive)
                    page.x = -nav.width * nav.parallax
            } else {
                page.visible = false
                page.enabled = false
            }
        }
    }

    Item {
        id: pageLayer
        anchors.fill: parent
        clip: true
    }

    MouseArea {
        id: edgeSwipe

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: nav.edgeWidth
        z: 9999

        enabled: nav.swipeBackEnabled
                 && nav.stack.length > 1
                 && !nav.transitionActive

        preventStealing: true
        acceptedButtons: Qt.LeftButton

        property real startSceneX: 0
        property real lastSceneX: 0
        property real lastTime: 0
        property real swipeVelocity: 0

        property Item currentPage: null
        property Item previousPage: null

        onPressed: function(mouse) {
            cancelAnim.stop()
            completePopAnim.stop()
            previousAnim.stop()

            startSceneX = mapToItem(nav, mouse.x, mouse.y).x
            lastSceneX = startSceneX
            lastTime = Date.now()
            swipeVelocity = 0

            currentPage = nav.stack[nav.stack.length - 1]
            previousPage = nav.stack[nav.stack.length - 2]

            nav.dragging = true

            currentPage.enabled = true

            if (previousPage) {
                previousPage.visible = true
                previousPage.enabled = false
                previousPage.x = -nav.width * nav.parallax
            }
        }

        onPositionChanged: function(mouse) {
            if (!nav.dragging || !currentPage)
                return

            var sceneX = mapToItem(nav, mouse.x, mouse.y).x
            var now = Date.now()
            var dt = Math.max(1, now - lastTime)
            var delta = sceneX - lastSceneX

            swipeVelocity = delta / dt * 1000

            lastSceneX = sceneX
            lastTime = now

            var dx = Math.max(0, sceneX - startSceneX)

            currentPage.x = Math.min(dx, nav.width)

            if (previousPage)
                previousPage.x = -nav.width * nav.parallax + currentPage.x * nav.parallax
        }

        onReleased: finishSwipe()
        onCanceled: finishSwipe()

        function finishSwipe() {
            if (!currentPage)
                return

            var passedMiddle = currentPage.x > nav.width / 2
            var fastSwipeRight = swipeVelocity > nav.velocityPopThreshold
            var shouldPop = passedMiddle || fastSwipeRight

            nav.dragging = false
            nav.transitionActive = true

            if (shouldPop) {
                completePopAnim.targetItem = currentPage
                completePopAnim.pageToDestroy = currentPage
                completePopAnim.fromValue = currentPage.x
                completePopAnim.toValue = nav.width
                completePopAnim.duration = nav.popDuration
                completePopAnim.start()

                if (previousPage) {
                    previousAnim.targetItem = previousPage
                    previousAnim.fromValue = previousPage.x
                    previousAnim.toValue = 0
                    previousAnim.duration = nav.popDuration
                    previousAnim.start()
                }
            } else {
                cancelAnim.targetItem = currentPage
                cancelAnim.fromValue = currentPage.x
                cancelAnim.toValue = 0
                cancelAnim.duration = nav.cancelDuration
                cancelAnim.start()

                if (previousPage) {
                    previousAnim.targetItem = previousPage
                    previousAnim.fromValue = previousPage.x
                    previousAnim.toValue = -nav.width * nav.parallax
                    previousAnim.duration = nav.cancelDuration
                    previousAnim.start()
                }
            }

            currentPage = null
            previousPage = null
        }
    }

    NumberAnimation {
        id: pushAnim

        property Item targetItem
        property real fromValue: 0
        property real toValue: 0

        target: targetItem
        property: "x"
        from: fromValue
        to: toValue
        duration: nav.pushDuration
        easing.type: Easing.OutCubic

        onFinished: {
            nav.transitionActive = false
            nav.updateVisibility()
        }
    }

    NumberAnimation {
        id: cancelAnim

        property Item targetItem
        property real fromValue: 0
        property real toValue: 0

        target: targetItem
        property: "x"
        from: fromValue
        to: toValue
        duration: nav.cancelDuration
        easing.type: Easing.OutCubic

        onFinished: {
            nav.transitionActive = false
            nav.updateVisibility()
        }
    }

    NumberAnimation {
        id: previousAnim

        property Item targetItem
        property real fromValue: 0
        property real toValue: 0

        target: targetItem
        property: "x"
        from: fromValue
        to: toValue
        duration: nav.cancelDuration
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: completePopAnim

        property Item targetItem
        property Item pageToDestroy
        property real fromValue: 0
        property real toValue: 0

        target: targetItem
        property: "x"
        from: fromValue
        to: toValue
        duration: nav.popDuration
        easing.type: Easing.OutCubic

        onFinished: {
            if (pageToDestroy) {
                nav.stack.pop()
                pageToDestroy.destroy()
                nav.stack = nav.stack
                nav.pagePopped(pageToDestroy)
            }

            pageToDestroy = null
            nav.transitionActive = false
            nav.updateVisibility()
        }
    }

    onWidthChanged: updateVisibility()
    onHeightChanged: updateVisibility()
}
