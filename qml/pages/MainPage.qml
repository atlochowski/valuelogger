import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.notifications 1.0
import harbour.valuelogger 1.0

import "../components"
import "../js/debug.js" as Debug

Page {
    id: mainPage

    readonly property real fullHeight: isPortrait ? Screen.height : Screen.width
    readonly property bool darkOnLight: 'colorScheme' in Theme && Theme.colorScheme === Theme.DarkOnLight

    signal plotSelected()

    function addParameter(index, oldParName, oldParDesc, oldPlotColor) {
        var dialog = pageStack.push(Qt.resolvedUrl("ParameterPage.qml"), {
            "allowedOrientations": allowedOrientations
        })

        dialog.accepted.connect(function() {
            Debug.log("dialog accepted")
            Debug.log("Name:", dialog.parameterName)
            Debug.log("Description:", dialog.parameterDescription)
            Debug.log("Color:", dialog.plotColor)

            Logger.addParameter(dialog.parameterName, dialog.parameterDescription, true, dialog.plotColor)
        })
    }

    Notification {
        id: notification
        expireTimeout: 2500
        Component.onCompleted: {
            if ("icon" in notification) {
                notification.icon = Qt.binding(function() { return Qt.resolvedUrl("../images/" + (darkOnLight ? "icon-cover-plot-dark.svg" : "icon-cover-plot.svg")) })
            }
        }
    }

    SilicaFlickable {
        id: mainFlickable

        width: parent.width
        height: fullHeight
        contentHeight: height

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"), {
                    "allowedOrientations": allowedOrientations
                })
            }

            MenuItem {
                text: qsTr("Export to CSV")
                visible: Logger.visualizeCount > 0
                onClicked: {
                    notification.previewBody = qsTr("Exported to %1").arg(Logger.exportToCSV())
                    notification.publish()
                }
            }

            MenuItem {
                text: qsTr("Add new parameter")
                onClicked: addParameter()
            }
        }

        PageHeader {
            id: header

            title: "Value Logger"
        }

        Loader {
            active: Logger.count === 0
            sourceComponent: Component {
                ViewPlaceholder {
                    enabled: true
                    flickable: mainFlickable
                    text: qsTr("No parameters.")
                    hintText: qsTr("Open the pulley menu to add one.")
                }
            }
        }

        SilicaListView {
            width: parent.width
            clip: true

            model: Logger

            anchors {
                top: header.bottom
                bottom: plotButton.top
                bottomMargin: Theme.paddingLarge
            }

            delegate: ListItem {
                id: parameterItem

                readonly property string parName: model.name
                readonly property string parDescription: model.description

                onClicked: visualize = !visualize
                contentHeight: Theme.itemSizeMedium
                menu: Component {
                    ContextMenu {
                        MenuItem {
                            // Allow 5 items only in portrait
                            visible: mainPage.isPortrait
                            text: qsTr("Plot")
                            onClicked: parameterItem.plotParameter()
                        }
                        MenuItem {
                            text: qsTr("Show raw data")
                            onClicked: parameterItem.showRawData()
                        }
                        MenuItem {
                            text: qsTr("Edit")
                            onClicked: parameterItem.editParameter()
                        }
                        MenuItem {
                            text: qsTr("Pair")
                            enabled: Logger.count > 1
                            onClicked: parameterItem.pairParameter()
                        }
                        MenuItem {
                            text: qsTr("Remove")
                            onClicked: parameterItem.removeParameter()
                        }
                    }
                }

                ListView.onRemove: animateRemoval(parameterItem)

                function plotParameter() {
                    pageStack.push(Qt.resolvedUrl("DrawData.qml"), {
                        "allowedOrientations": mainPage.allowedOrientations,
                        "parInfo": [{
                            "name": parName,
                            "description": model.description,
                            "plotcolor": model.plotcolor,
                            "datatable": model.datatable
                        }]
                    })
                }

                function showRawData() {
                    var dialog = pageStack.push(Qt.resolvedUrl("ShowData.qml"), {
                        "allowedOrientations": allowedOrientations,
                        "parName": parName,
                        "parDescription": parDescription,
                        "dataTable": model.datatable
                    })
                }

                function editParameter() {
                    Debug.log("EDIT", model.index, parName)
                    var dialog = pageStack.push(Qt.resolvedUrl("ParameterPage.qml"), {
                        "allowedOrientations": allowedOrientations,
                        "parameterName": parName,
                        "parameterDescription": parDescription,
                        "plotColor": model.plotcolor,
                        "pageTitle": qsTr("Edit parameter")
                    })

                    dialog.accepted.connect(function() {
                        Debug.log("EDIT dialog accepted")
                        Debug.log("Name:", dialog.parameterName)
                        Debug.log("Description:", dialog.parameterDescription)
                        Debug.log("Color:", dialog.plotColor)
                        Logger.editParameterAt(model.index, dialog.parameterName,
                            dialog.parameterDescription, model.visualize, dialog.plotColor,
                            model.pairedtable)
                    })
                }

                function removeParameter() {
                    remorseAction(qsTr("Deleting"), function() {
                        Logger.deleteParameterAt(model.index)
                    })
                }

                function pairParameter() {
                    var dialog = pageStack.push(Qt.resolvedUrl("AddPair.qml"), {
                        "allowedOrientations": allowedOrientations,
                        "pairFirstTable": model.datatable,
                        "pairSecondTable": model.pairedtable,
                        "title": parName
                    })
                    dialog.accepted.connect(function() {
                        Debug.log("Add pair dialog accepted")
                        Debug.log(dialog.pairSecondTable)
                        model.pairedtable = dialog.pairSecondTable
                    })
                }

                Rectangle {
                    id: plotColorLegend

                    width: Theme.paddingSmall
                    height: Theme.itemSizeSmall/2
                    anchors.verticalCenter: parent.verticalCenter
                    layer.enabled: parameterItem.highlighted && !parameterItem.menuOpen
                    layer.effect: PressEffect { source: plotColorLegend }
                    color: plotcolor
                    visible: visualize
                }

                Item {
                    width: parent.width - Theme.horizontalPageMargin
                    height: parent.height

                    Switch {
                        id: parSwitch

                        anchors.verticalCenter: parent.verticalCenter
                        checked: visualize
                        automaticCheck: false
                        onClicked: visualize = !visualize
                    }

                    Column {
                        anchors {
                            left: parSwitch.right
                            right: rightArea.left
                            rightMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }

                        Label {
                            width: parent.width
                            color: parameterItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                            truncationMode: TruncationMode.Fade
                            text: parName
                        }
                        Label {
                            width: parent.width
                            font {
                                pixelSize: Theme.fontSizeSmall
                                italic: true
                            }
                            truncationMode: TruncationMode.Fade
                            color: parameterItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            text: parDescription
                            visible: text !== ""
                        }
                    }

                    Row {
                        id: rightArea

                        height: parent.height
                        spacing: Theme.paddingLarge
                        anchors.right: parent.right

                        HighlightIcon {
                            id: pairIcon
                            source: "image://theme/icon-m-link"
                            anchors.verticalCenter: parent.verticalCenter
                            sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)
                            highlightColor: Theme.primaryColor
                            visible: model.pairedtable !== ""
                        }

                        IconButton {
                            id: addValueButton

                            anchors.verticalCenter: parent.verticalCenter
                            icon.source: "image://theme/icon-m-add"
                            onClicked: {
                                Debug.log("clicked add value button")
                                var dialog = pageStack.push(Qt.resolvedUrl("AddValue.qml"), {
                                    "allowedOrientations": allowedOrientations,
                                    "parameterName": parName,
                                    "parameterDescription": parDescription
                                })

                                var paired
                                if (model.pairedtable) {
                                    Debug.log("this is a paired parameter")
                                    for (var i = 0; i < Logger.count; i++) {
                                        var par2 = Logger.get(i)
                                        if (par2.datatable === model.pairedtable) {
                                            paired = par2
                                            Debug.log("found", par2.name, par2.description)
                                            break
                                        }
                                    }
                                }

                                if (paired) {
                                    var pairdialog = pageStack.pushAttached(Qt.resolvedUrl("AddValue.qml"), {
                                        "allowedOrientations": allowedOrientations,
                                        "nowDate": dialog.nowDate,
                                        "nowTime": dialog.nowTime,
                                        "parameterName": paired.name,
                                        "parameterDescription": paired.description,
                                        "paired": true
                                    })

                                    pairdialog.accepted.connect(function() {
                                        var time = dialog.nowDate + " " + dialog.nowTime
                                        var pairedtime = pairdialog.nowDate + " " + pairdialog.nowTime

                                        Debug.log("paired dialog accepted")
                                        Debug.log(" value", dialog.value)
                                        Debug.log(" annotation", dialog.annotation)
                                        Debug.log(" time", time)
                                        Debug.log("  paired value", pairdialog.value)
                                        Debug.log("  paired annotation", pairdialog.annotation)
                                        Debug.log("  paired time", pairedtime)

                                        Logger.addData(model.datatable, dialog.value, dialog.annotation, time)
                                        Logger.addData(model.pairedtable, pairdialog.value, pairdialog.annotation, pairedtime)
                                    })
                                } else {
                                    dialog.accepted.connect(function() {
                                        var time = dialog.nowDate + " " + dialog.nowTime
                                        Debug.log("dialog accepted")
                                        Debug.log(" value", dialog.value)
                                        Debug.log(" annotation", dialog.annotation)
                                        Debug.log(" date", dialog.nowDate)
                                        Debug.log(" time", dialog.nowTime)

                                        Logger.addData(model.datatable, dialog.value, dialog.annotation, time)
                                    })
                                }
                            }
                        }
                    }
                }
            }

            VerticalScrollDecorator { }
        }


        Button {
            id: plotButton

            anchors {
                bottom: parent.bottom
                bottomMargin: Theme.paddingLarge
                horizontalCenter: parent.horizontalCenter
            }

            text: qsTr("Plot selected")
            enabled: Logger.visualizeCount > 0
            visible: Logger.count > 0
            onClicked: mainPage.plotSelected()
        }
    }
}
