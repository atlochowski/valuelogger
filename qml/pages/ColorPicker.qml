import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.valuelogger 1.0

import "../js/debug.js" as Debug
import "../components"

Dialog {
    id: thisDialog

    property color color
    property alias colors: colorModel.colors

    forwardNavigation: false

    signal resetColors()

    SilicaGridView {
        id: grid

        cellWidth: Math.floor(width/cellsPerRow)
        cellHeight: cellWidth
        anchors.fill: parent

        model: ColorModel { id: colorModel }

        VerticalScrollDecorator {}

        PullDownMenu {
            MenuItem {
                text: qsTr("Reset colors")
                onClicked: thisDialog.resetColors()
            }
        }

        property Item dragItem
        property int pageHeaderHeight
        readonly property int cellsPerRow: Math.floor(width / Theme.itemSizeHuge)

        header: DialogHeader {
            dialog: thisDialog
            acceptText: qsTr("Select color")
            spacing: 0
            Component.onCompleted: grid.pageHeaderHeight = height
            onHeightChanged: grid.pageHeaderHeight = height
        }

        delegate: MouseArea {
            id: colorDelegate

            width: grid.cellWidth
            height: grid.cellHeight

            drag.target: dragging ? colorItem : null
            drag.axis: Drag.XandYAxis

            readonly property bool highlighted: (pressed && containsMouse)
            readonly property bool dragging: grid.dragItem === colorDelegate

            Rectangle {
                id: colorItem

                width: grid.cellWidth
                height: grid.cellHeight
                color: model.color
                scale: !colorDelegate.dragging ? 1 : isTrashed ? 0.8 : 1.1
                opacity: isTrashed ? 0.8 : 1
                layer.enabled: colorDelegate.highlighted || colorDelegate.dragging || scale > 1
                layer.effect: PressEffect { source: colorItem }

                readonly property bool isTrashed: model.itemType === ColorModel.TrashedItem
                readonly property int index: model.index
                property real returnX
                property real returnY
                property bool snappingBack

                Behavior on opacity { FadeAnimation { } }
                Behavior on scale {
                    NumberAnimation {
                        easing.type: Easing.InQuad
                        duration: 150
                    }
                }

                Image {
                    anchors.centerIn: parent
                    source: opacity ? ("image://theme/graphic-close-app?" + deriveColor(model.color)) : ""
                    sourceSize: Qt.size(Theme.iconSizeLarge, Theme.iconSizeLarge)
                    opacity: (model.itemType === ColorModel.TrashedItem) ? 0.8 : 0
                    visible: opacity > 0
                    Behavior on opacity { FadeAnimation { } }

                    function deriveColor(color) {
                        var gray = 0.299 * color.r + 0.587 * color.g + 0.114 *color.b
                        var v = (gray > 0.5) ? 0 : 1
                        return Qt.rgba(v, v, v, color.a)
                    }
                }

                states: [
                    State {
                        name: "dragging"
                        when: colorDelegate.dragging
                        ParentChange {
                            target: colorItem
                            parent: grid
                            x: colorDelegate.mapToItem(grid, 0, 0).x
                            y: colorDelegate.mapToItem(grid, 0, 0).y
                        }
                    },
                    State {
                        name: "snappingBack"
                        when: !colorDelegate.dragging && colorItem.snappingBack
                        ParentChange {
                            target: colorItem
                            parent: grid
                            x: colorItem.returnX
                            y: colorItem.returnY
                        }
                    },
                    State {
                        name: "idle"
                        when: !colorDelegate.dragging && !colorItem.snappingBack
                        ParentChange {
                            target: colorItem
                            parent: colorDelegate
                            x: 0
                            y: 0
                        }
                    }
                ]

                transitions: [
                    Transition {
                        to: "snappingBack"
                        SequentialAnimation {
                            SmoothedAnimation {
                                properties: "x,y"
                                duration: 150
                            }
                            ScriptAction { script: colorItem.snappingBack = false }
                        }
                    },
                    Transition {
                        to: "idle"
                        ScriptAction { script: colorModel.dragPos = -1 }
                    }
                ]

                onStateChanged: Debug.log(colorItem.index, colorDelegate.dragging, state)

                Connections {
                    target: colorDelegate.dragging ? colorItem : null
                    onXChanged: colorItem.updateDragPos()
                    onYChanged: colorItem.scrollAndUpdateDragPos()
                }

                Connections {
                    target: colorDelegate.dragging ? grid : null
                    onContentXChanged: colorItem.updateDragPos()
                    onContentYChanged: colorItem.updateDragPos()
                }

                function scrollAndUpdateDragPos() {
                    if (y < grid.pageHeaderHeight) {
                        if (grid.contentY > grid.originY) {
                            scrollAnimation.to = grid.originY
                            if (!scrollAnimation.running) {
                                scrollAnimation.duration = Math.max(scrollAnimation.minDuration,
                                    Math.min(scrollAnimation.maxDuration,
                                    (grid.contentY - grid.originY)*1000/grid.height))
                                scrollAnimation.start()
                            }
                        }
                    } else if ((y + height) > grid.height) {
                        var maxContentY = grid.contentHeight - grid.height - grid.pageHeaderHeight
                        if (grid.contentY < maxContentY) {
                            scrollAnimation.to = maxContentY
                            if (!scrollAnimation.running) {
                                scrollAnimation.duration = Math.max(scrollAnimation.minDuration,
                                    Math.min(scrollAnimation.maxDuration,
                                    (maxContentY - grid.contentY)*1000/grid.height))
                                scrollAnimation.start()
                            }
                        }
                    } else {
                        scrollAnimation.stop()
                    }
                    updateDragPos()
                }

                function updateDragPos() {
                    var row = Math.floor((grid.contentY + y + height/2)/grid.cellHeight)
                    colorModel.dragPos = grid.cellsPerRow * row + Math.floor((grid.contentX + x + width/2)/grid.cellWidth)
                }

                Rectangle {
                    border {
                        width: Theme.paddingSmall
                        color: Theme.highlightBackgroundColor
                    }
                    anchors.fill: parent
                    color: "transparent"
                    visible: colorModel.dragPos < 0 &&
                        colorItem.color === thisDialog.color &&
                        colorItem.index === colorModel.indexOf(thisDialog.color)
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: model.itemType === ColorModel.AddItem
                color: colorDelegate.highlighted ? highlightColor : "transparent"
                readonly property color highlightColor: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)

                Image {
                    anchors.centerIn: parent
                    source: parent.visible ? ("image://theme/icon-m-add?" + (colorDelegate.highlighted ? Theme.highlightColor : Theme.primaryColor)) : ""
                    sourceSize: Qt.size(Theme.iconSizeExtraLarge, Theme.iconSizeExtraLarge)
                }
            }

            onClicked: {
                if (model.itemType === ColorModel.ColorItem) {
                    thisDialog.color = model.color
                    thisDialog.forwardNavigation = true
                    thisDialog.accept()
                } else {
                    var editor = pageStack.push(Qt.resolvedUrl("ColorEditor.qml"), {
                        "allowedOrientations": allowedOrientations,
                        "initialColor": thisDialog.color
                    })
                    editor.accepted.connect(function() {
                        Debug.log("Adding", editor.selectedColor)
                        colorModel.addColor(editor.selectedColor)
                    })
                }
            }

            onPressAndHold: {
                if (model.itemType === ColorModel.ColorItem) {
                    grid.dragItem = colorDelegate
                }
            }
            onReleased: stopDrag()
            onCanceled: stopDrag()

            onDraggingChanged: {
                if (dragging) {
                    colorModel.dragPos = index
                }
            }

            function stopDrag() {
                if (grid.dragItem === colorDelegate) {
                    var returnPoint = mapToItem(grid, 0, 0)
                    colorItem.returnX = returnPoint.x
                    colorItem.returnY = returnPoint.y
                    colorItem.snappingBack = (colorItem.returnX !== colorItem.x || colorItem.returnY !== colorItem.y)
                    grid.dragItem = null
                }
            }
        }

        SmoothedAnimation {
            id: scrollAnimation
            target: grid
            duration: minDuration
            properties: "contentY"

            readonly property int minDuration: 250
            readonly property int maxDuration: 5000
        }

        addDisplaced: Transition { SmoothedAnimation { properties: "x,y"; duration: 150 } }
        moveDisplaced: Transition { SmoothedAnimation { properties: "x,y"; duration: 150 } }
        removeDisplaced: Transition { SmoothedAnimation { properties: "x,y"; duration: 150 } }
    }
}
