import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: page
    title: qsTr("History")
    property bool wideLayout: false
    property color canvasColor: "#F3F7F5"
    property color surfaceColor: "#FFFFFF"
    property color mutedColor: "#5D6F69"

    background: Rectangle {
        color: page.canvasColor
    }

    ColumnLayout {
        width: Math.min(page.width, page.wideLayout ? 920 : 600)
        x: Math.max(0, (page.width - width) / 2)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: page.wideLayout ? 28 : 20
            Layout.rightMargin: page.wideLayout ? 28 : 20
            Layout.topMargin: page.wideLayout ? 28 : 20
            Layout.bottomMargin: 16
            spacing: 4

            Label {
                text: qsTr("Scan history")
                font.pixelSize: Math.round((page.wideLayout ? 28 : 23) * appSettings.fontScale)
                font.bold: true
            }
            Label {
                text: qsTr("Recent codes stored only on this device")
                color: page.mutedColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? banner.implicitHeight + 16 : 0
            visible: !appSettings.historyEnabled
            color: Material.color(Material.Amber, Material.Shade100)

            Label {
                id: banner
                anchors.fill: parent
                anchors.margins: 8
                text: qsTr("History is turned off. New scans will not be saved.")
                wrapMode: Text.WordWrap
                color: "#5D4037"
                Accessible.name: text
            }
        }

        ListView {
            id: historyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            spacing: 6
            clip: true
            model: scanHistory

            delegate: ItemDelegate {
                width: historyList.width
                Accessible.name: model.content

                background: Rectangle {
                    color: page.surfaceColor
                    radius: 6
                }

                function typeIcon(type) {
                    if (type === "url") return "🔗"
                    if (type === "encrypted") return "🔒"
                    return "📄"
                }

                contentItem: ColumnLayout {
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: typeIcon(model.contentType)
                            font.pixelSize: Math.round(16 * appSettings.fontScale)
                        }

                        Label {
                            text: model.content
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: Math.round(14 * appSettings.fontScale)
                        }
                    }

                    Label {
                        text: model.timestamp
                        font.pixelSize: Math.round(11 * appSettings.fontScale)
                        opacity: 0.6
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: historyList.count === 0
                text: qsTr("No scans yet")
                opacity: 0.5
            }
        }
    }

    footer: Pane {
        padding: page.wideLayout ? 16 : 12
        Material.elevation: 0

        background: Rectangle {
            color: page.surfaceColor

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.22)
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Item { Layout.fillWidth: true }

            Button {
                id: clearButton
                enabled: scanHistory !== null && scanHistory.count > 0
                Accessible.name: qsTr("Clear all history")
                onClicked: scanHistory.clear()

                readonly property color dangerColor: "#D32F2F"
                readonly property color contentColor: enabled ? "#FFFFFF" : page.mutedColor

                Layout.preferredHeight: 46
                leftPadding: 22
                rightPadding: 22

                contentItem: RowLayout {
                    spacing: 8
                    Label {
                        text: "🗑"
                        font.pixelSize: Math.round(15 * appSettings.fontScale)
                        color: clearButton.contentColor
                        verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        text: qsTr("Clear history")
                        font.pixelSize: Math.round(14 * appSettings.fontScale)
                        font.bold: true
                        color: clearButton.contentColor
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                background: Rectangle {
                    radius: height / 2
                    color: !clearButton.enabled
                           ? Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.16)
                           : clearButton.pressed ? Qt.darker(clearButton.dangerColor, 1.25)
                           : clearButton.hovered ? Qt.lighter(clearButton.dangerColor, 1.08)
                           : clearButton.dangerColor
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }
        }
    }
}
