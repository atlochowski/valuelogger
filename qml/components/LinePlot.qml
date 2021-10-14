/*
    Original Copyright (c) 2013 Jussi Sainio
 
    Modified to support multiple lines for valuelogger 2014 Kimmo Lindholm

    More or less completely rewritten in 2021 by Slava Monich

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.valuelogger 1.0

import "../js/debug.js" as Debug

Item {
    property var parInfoModel
    property bool dragging

    readonly property int thinLine: Math.max(2, Math.floor(Theme.paddingSmall/3))
    readonly property int fontSize: Theme.fontSizeTiny
    readonly property bool fontBold: true

    property real min: 0.0
    property real max: 1.0

    property date xstart: new Date()
    property date xend: new Date()

    property real minValue
    property real maxValue

    property date minTime
    property date maxTime

    property real lastKnownWidth
    property real lastKnownHeight

    /* Called by the container when it gets its geometry settled */
    function enableSizeTracking() {
        lastKnownWidth = width
        lastKnownHeight = height
    }

    Component.onCompleted: {
        /* Calculate optimal time and value ranges */
        if (graphs.count > 0) {
            var model, i = 0

            /* Find first non-empty model */
            while (i < graphs.count) {
                model = graphs.itemAt(i++).model
                if (model.count > 0) {
                    minTime = model.minTime
                    maxTime = model.maxTime
                    minValue = model.minValue
                    maxValue = model.maxValue
                    break
                }
            }

            Debug.log("minTime:", minTime, minTime.getTime())
            Debug.log("maxTime:", maxTime, maxTime.getTime())
            Debug.log("minValue:", minValue)
            Debug.log("maxValue:", maxValue)

            /* Process the remaining models */
            while (i < graphs.count) {
                model = graphs.itemAt(i++).model
                if (model.count > 0) {
                    if (minTime.getTime() > model.minTime.getTime()) {
                        Debug.log("minTime:", minTime, "=>", model.minTime, model.minTime.getTime())
                        minTime = model.minTime
                    }
                    if (maxTime.getTime() < model.maxTime.getTime()) {
                        Debug.log("maxTime:", maxTime, "=>", model.maxTime, model.maxTime.getTime())
                        maxTime = model.maxTime
                    }
                    if (minValue > model.minValue) {
                        Debug.log("min:", minValue, "=>", model.minValue)
                        minValue = model.minValue
                    }
                    if (maxValue < model.maxValue) {
                        Debug.log("max:", maxValue, "=>", model.maxValue)
                        maxValue = model.maxValue
                    }
                }
            }
        } else {
            minTime = maxTime = new Date()
            minValue = maxValue = 0
        }
        updateScale()
    }

    function distanceX(p1, p2){
        return Math.max(p1.x, p2.x) - Math.min(p1.x, p2.x)
    }

    function distanceY(p1, p2) {
        return Math.max(p1.y, p2.y) - Math.min(p1.y, p2.y)
    }

    function updateVerticalScale() {
        var fullSpan = maxValue - minValue, visibleSpan, shift
        if (fullSpan > 0) {
            visibleSpan = fullSpan / pinchZoom.scaleY
            shift = fullSpan * ( 1 +  pinchMove.moveY / canvas.height / pinchZoom.scaleY) - visibleSpan
        } else {
            visibleSpan = 1
            shift = -0.5
        }

        min = minValue + shift
        max = min + visibleSpan

        valueMax.text = max.toFixed(2)
        valueMin.text = min.toFixed(2)
    }

    function updateHorizontalScale() {
        var t1 = new Date()
        var t2 = new Date()
        var fullSpan = maxTime.getTime() - minTime.getTime(), visibleSpan, shift
        if (fullSpan > 0) {
            visibleSpan = fullSpan / pinchZoom.scaleX
            shift = fullSpan * pinchMove.moveX / canvas.width / pinchZoom.scaleX
        } else {
            visibleSpan = 1000
            shift = -500
        }

        t1.setTime(minTime.getTime() - shift)
        t2.setTime(t1.getTime() + visibleSpan)

        xstart = t1
        xend = t2

        xStart.text = Qt.formatDateTime(xstart, "dd.MM.yyyy hh:mm")
        xEnd.text = Qt.formatDateTime(xend, "dd.MM.yyyy hh:mm")
    }

    function updateScale() {
        updateVerticalScale()
        updateHorizontalScale()
    }

    onWidthChanged: {
        if (lastKnownWidth > 0) {
            var newMoveX = Math.round(pinchMove.moveX * width / lastKnownWidth)
            Debug.log("width", lastKnownWidth, "=>", width)
            Debug.log("moveX", pinchMove.moveX, "=>", newMoveX)
            pinchMove.moveX = newMoveX
            lastKnownWidth = width
            sizeChangedTimer.restart()
        }
    }

    onHeightChanged: {
        if (lastKnownHeight  > 0) {
            var newMoveY = Math.round(pinchMove.moveY * height / lastKnownHeight)
            Debug.log("height", lastKnownHeight, "=>", height)
            Debug.log("moveY", pinchMove.moveY, "=>", newMoveY)
            pinchMove.moveY = newMoveY
            lastKnownHeight = height
            sizeChangedTimer.restart()
        }
    }

    Timer {
        id: sizeChangedTimer
        interval: 0
        onTriggered: updateScale()
    }

    Text {
        id: xStart
        color: Theme.primaryColor
        font {
            pixelSize: fontSize
            bold: fontBold
        }
        anchors {
            left: parent.left
            top: parent.top
        }
    }

    Text {
        id: xEnd
        color: Theme.primaryColor
        font {
            pixelSize: fontSize
            bold: fontBold
        }
        anchors {
            right: parent.right
            top: parent.top
        }
    }

    Text {
        id: valueMax
        color: Theme.primaryColor
        font {
            pixelSize: fontSize
            bold: fontBold
        }
        anchors {
            left: parent.left
            top: xStart.bottom
        }
    }

    Text {
        id: valueMin
        color: Theme.primaryColor
        font {
            pixelSize: fontSize
            bold: fontBold
        }
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
    }

    ListView {
        id: legend

        readonly property real itemHeight: Math.round(fontSize * 3 / 2)

        anchors {
            left: grid.left
            leftMargin: Math.round(grid.width/grid.horizontalCount/2)
            right: grid.right
            rightMargin: Theme.horizontalPageMargin
            top: grid.top
            topMargin: Theme.paddingLarge
        }

        z: 11
        height: itemHeight * count
        model: parInfoModel
        visible: opacity > 0

        delegate: Item {
            height: legend.itemHeight
            width: legend.width

            Rectangle {
                id: legendColor
                width: Theme.paddingLarge
                height: Theme.paddingSmall/2
                color: modelData.plotcolor
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: legendColor.right
                    leftMargin: Theme.paddingSmall
                    right: parent.right
                }
                font {
                    pixelSize: fontSize
                    bold: fontBold
                }
                text: modelData.name
                truncationMode: TruncationMode.Fade
            }
        }

        Behavior on opacity {
            FadeAnimation { duration: 500 }
        }

        onOpacityChanged: {
            if (opacity === 1.0) {
                legendVisibility.start()
            }
        }

        Timer {
            id: legendVisibility

            interval: 2000
            running: true
            onTriggered: legend.opacity = 0.0
        }
    }

    ShaderEffectSource {
        id: grid

        readonly property int horizontalCount: 6
        readonly property int verticalCount: 5

        width: parent.width
        anchors {
            top: valueMax.bottom
            bottom: valueMin.top
        }
        opacity: 0.3
        sourceItem: Item {
            width: grid.width
            height: grid.height
            /* Vertical grid lines */
            Rectangle {
                x: 0
                width: thinLine
                height: parent.height
                color: Theme.primaryColor
            }
            Rectangle {
                x: parent.width - width
                width: thinLine
                height: parent.height
                color: Theme.primaryColor
            }
            Repeater {
                model: grid.horizontalCount - 1
                delegate: VDashLine {
                    x: Math.round((index + 1) * (parent.width - width)/grid.horizontalCount)
                    width: thinLine
                    height: parent.height
                    color: Theme.primaryColor
                }
            }
            /* Horizontal grid lines */
            Rectangle {
                y: 0
                width: parent.width
                height: thinLine
                color: Theme.primaryColor
            }
            Rectangle {
                y: parent.height - thinLine
                width: parent.width
                height: thinLine
                color: Theme.primaryColor
            }
            Repeater {
                model: GridModel {
                    minValue: min
                    maxValue: max
                    size: canvas.height
                    maxCount: fixedGrids ? 4 : 7
                    fixedGrids: Settings.horizontalGridLinesStyle === Settings.GridLinesFixed
                }
                delegate: Column {
                    y: Math.round(grid.height - model.coordinate - thinLine)
                    width: grid.width
                    /* Hide is when it gets too close to the edge */
                    visible: opacity > 0
                    opacity: y < Theme.paddingLarge ? (y / Theme.paddingLarge) :
                        ((grid.height - y) < 2*height) ? ((grid.height - y) / (2*height)) : 1

                    HDashLine {
                        width: parent.width
                        height: thinLine
                        color: Theme.primaryColor
                    }

                    Row {
                        x: Theme.paddingSmall

                        Text {
                            x: Theme.paddingSmall
                            width: grid.width/2 - parent.x
                            color: Theme.primaryColor
                            text: model.text
                            horizontalAlignment: Text.AlignLeft
                            font {
                                pixelSize: fontSize
                                bold: fontBold
                            }
                            /* Keep is visible to participate in the layout */
                            opacity: Settings.leftGridLabels ? 1 : 0
                        }

                        Text {
                            x: Theme.paddingSmall
                            width: grid.width/2 - parent.x
                            color: Theme.primaryColor
                            text: model.text
                            horizontalAlignment: Text.AlignRight
                            font {
                                pixelSize: fontSize
                                bold: fontBold
                            }
                            /* This one can be hidden if it's not needed */
                            visible: Settings.rightGridLabels
                            onXChanged: Debug.log(x)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: canvas

        width: parent.width
        anchors {
            top: valueMax.bottom
            bottom: valueMin.top
        }

        PinchArea {
            id: pinchZoom
            anchors.fill: canvas

            property real scaleX: 1
            property real scaleY: 1
            property real pinchScaleX: 1
            property real pinchScaleY: 1
            property point pinchCenter
            property bool scalingHorizontally

            onPinchFinished: {
            }
            onPinchStarted: {
                pinchScaleX = scaleX
                pinchScaleY = scaleY
                pinchMove.startMoveX = pinchMove.moveX
                pinchMove.startMoveY = pinchMove.moveY
                pinchCenter = pinch.center

                var dx = distanceX(pinch.point1, pinch.point2)
                var dy = distanceY(pinch.point1, pinch.point2)
                scalingHorizontally = (dx > dy)
            }
            onPinchUpdated: {
                if (scalingHorizontally) {
                    scaleX = pinchScaleX * pinch.scale
                    pinchMove.moveX = pinchCenter.x - (pinchCenter.x - pinchMove.startMoveX) / pinchScaleX * scaleX
                } else {
                    scaleY = pinchScaleY * pinch.scale
                    pinchMove.moveY = pinchCenter.y - (pinchCenter.y - pinchMove.startMoveY) / pinchScaleY * scaleY
                }
                updateScale()
            }

            MouseArea {
                id: pinchMove

                anchors.fill: parent

                property real moveX
                property real moveY
                property real startMoveX
                property real startMoveY
                property real pressX
                property real pressY

                onClicked: {
                    legend.opacity = 1.0
                    legendVisibility.restart()
                }

                onPressed: {
                    dragging = true
                    startMoveX = moveX
                    startMoveY = moveY
                    pressX = mouseX
                    pressY = mouseY
                }
                onDoubleClicked: {
                    Debug.log("resetting the graph")
                    blockPositionChanges.restart()
                    pinchZoom.scaleX = 1
                    pinchZoom.scaleY = 1
                    startMoveX = moveX = 0
                    startMoveY = moveY = 0
                    pressX = mouseX
                    pressY = mouseY
                    updateScale()
                }
                onPositionChanged: {
                    if (!blockPositionChanges.running) {
                        moveX = Math.round(startMoveX + (mouseX - pressX))
                        moveY = Math.round(startMoveY + (mouseY - pressY))
                        updateScale()
                    }
                }
                onReleased: dragging = false
                onCanceled: dragging = false

                Timer {
                    id: blockPositionChanges
                    interval: 250
                }
            }
        }

        Repeater {
            id: graphs

            model: parInfoModel
            delegate: Graph {
                readonly property int minLineWidth: 2
                readonly property int maxLineWidth: Math.round(Theme.paddingSmall/2)
                anchors {
                    fill: parent
                    margins: thinLine
                }
                minValue: min
                maxValue: max
                minTime: xstart
                maxTime: xend
                lineWidth: paintedCount ? Math.max(Math.ceil(Math.min(maxLineWidth, width/paintedCount)), minLineWidth) : maxLineWidth
                color: modelData.plotcolor
                model: DataModel {
                    dataTable: modelData.datatable
                }
            }
        }
    }
}
