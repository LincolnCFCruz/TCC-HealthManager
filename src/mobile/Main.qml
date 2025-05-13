import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Basic

// ---------------------

import QtLocation
import QtPositioning

// ---------------------

Window {
    id: root

    title: qsTr("Athlete Manager")

    width: 640
    height: 480

    visible: true
    visibility: Window.FullScreen

    color: "#202020"

    // ---------------------

    property int currentPageIndex: 0

    // ---------------------

    property real temperature: 28.5
    property real pressure: 920.30
    property real altitude: 803.68

    // ---------------------

    property variant deviceList: ['ChestStrapDevice', "PC-01"]

    // ---------------------

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        spacing: 10

        Item {
            id: deviceNotch

            Layout.fillWidth: true
            height: 50

            Text {
                anchors.fill: parent

                text: "STATUS"
                font.pixelSize: 25

                color: "#FFFFFF"

                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            color: "#282828"

            radius: 5

            StackLayout {
                anchors.fill: parent

                currentIndex: currentPageIndex

                Item {
                    id: managerPage

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        spacing: 20

                        Rectangle {
                            id: heartRateItem

                            Layout.fillWidth: true
                            height: 30

                            radius: 5

                            color: "#484848"

                            Text {
                                anchors.fill: parent

                                text: `Heart Rate: ----`

                                font.pixelSize: 15

                                color: "#FFFFFF"

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            id: oxygenItem

                            Layout.fillWidth: true
                            height: 30

                            radius: 5

                            color: "#484848"

                            Text {
                                anchors.fill: parent

                                text: `Oxygen: ----`

                                font.pixelSize: 15

                                color: "#FFFFFF"

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1

                            color: "#999999"
                        }

                        Rectangle {
                            id: tempItem

                            Layout.fillWidth: true
                            height: 30

                            radius: 5

                            color: "#484848"

                            Text {
                                anchors.fill: parent

                                text: `Temp: ${temperature} ªC`

                                font.pixelSize: 15

                                color: "#FFFFFF"

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            id: pressItem

                            Layout.fillWidth: true
                            height: 30

                            radius: 5

                            color: "#484848"

                            Text {
                                anchors.fill: parent

                                text: `Press: ${pressure} hPa`

                                font.pixelSize: 15

                                color: "#FFFFFF"

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            id: altitudeItem

                            Layout.fillWidth: true
                            height: 30

                            radius: 5

                            color: "#484848"

                            Text {
                                anchors.fill: parent

                                text: `Alt: ${altitude} m`

                                font.pixelSize: 15

                                color: "#FFFFFF"

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1

                            color: "#999999"
                        }

                        Rectangle {
                            id: bodyItem

                            Layout.fillWidth: true
                            height: 30

                            radius: 5

                            color: "transparent"

                            Text {
                                anchors.fill: parent

                                text: `Body Inclination`

                                font.pixelSize: 15

                                color: "#999999"

                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            width: 200
                            height: 200

                            color: "transparent"

                            radius: 5

                            border.color: "#FFFFFF"
                            border.width: 1

                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                            Rectangle {
                                width: 10
                                height: 10

                                radius: 5

                                color: "#FFFFFF"

                                x: (parent.width / 2) - 5
                                y: (parent.height / 2) - 5
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }

                Item {
                    id: mapPage

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Plugin {
                        id: mapPlugin
                        name: "osm" // Use OpenStreetMap as the map provider
                        // For other providers you might need to specify parameters:
                        // PluginParameter { name: "osm.mapping.custom.host"; value: "https://a.tile.openstreetmap.org/" }
                    }

                    Map {
                        id: map
                        anchors.fill: parent
                        plugin: mapPlugin
                        center: QtPositioning.coordinate(-19.892101053989723, -43.93077939773494) // London coordinates
                        zoomLevel: 10

                        copyrightsVisible: false

                        // ---------------------

                        property geoCoordinate startCentroid

                        PinchHandler {
                            id: pinch
                            target: null
                            onActiveChanged: if (active) {
                                map.startCentroid = map.toCoordinate(pinch.centroid.position, false)
                            }
                            onScaleChanged: (delta) => {
                                map.zoomLevel += Math.log2(delta)
                                map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
                            }
                            onRotationChanged: (delta) => {
                                map.bearing -= delta
                                map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
                            }
                            grabPermissions: PointerHandler.TakeOverForbidden
                        }
                        WheelHandler {
                            id: wheel
                            // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
                            // Magic Mouse pretends to be a trackpad but doesn't work with PinchHandler
                            // and we don't yet distinguish mice and trackpads on Wayland either
                            acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                                             ? PointerDevice.Mouse | PointerDevice.TouchPad
                                             : PointerDevice.Mouse
                            rotationScale: 1/120
                            property: "zoomLevel"
                        }
                        DragHandler {
                            id: drag
                            target: null
                            onTranslationChanged: (delta) => map.pan(-delta.x, -delta.y)
                        }
                        Shortcut {
                            enabled: map.zoomLevel < map.maximumZoomLevel
                            sequence: StandardKey.ZoomIn
                            onActivated: map.zoomLevel = Math.round(map.zoomLevel + 1)
                        }
                        Shortcut {
                            enabled: map.zoomLevel > map.minimumZoomLevel
                            sequence: StandardKey.ZoomOut
                            onActivated: map.zoomLevel = Math.round(map.zoomLevel - 1)
                        }
                    }
                }

                Item {
                    id: devicesPage

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Text {
                            Layout.fillWidth: true
                            height: 25

                            text: "CONNECTED DEVICES"

                            font.pixelSize: 15

                            color: "#FFFFFF"

                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            model: deviceList.length

                            spacing: 20

                            delegate: Button {
                                width: ListView.view.width

                                text: deviceList[modelData]

                                onClicked: {
                                    console.log("Connecting...");
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            height: 50

            RowLayout {
                anchors.fill: parent

                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "MANAGER"

                        font.pixelSize: 15

                        color: (currentPageIndex === 0) ? "#FFBF00" : "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            currentPageIndex = 0
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "MAP"

                        font.pixelSize: 15

                        color: (currentPageIndex === 1) ? "#FFBF00" : "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            currentPageIndex = 1
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        text: "DEVICES"

                        font.pixelSize: 15

                        color: (currentPageIndex === 2) ? "#FFBF00" : "#ffffff"
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            currentPageIndex = 2
                        }
                    }
                }
            }
        }
    }
}
