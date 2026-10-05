import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: page
    title: qsTr("About")
    property bool wideLayout: false
    property color canvasColor: "#F1F5F3"
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#0B6B5E"
    property color mutedColor: "#4B5754"
    readonly property real sideMargin: page.wideLayout ? 28 : 16
    readonly property color dividerColor: Material.theme === Material.Dark ? Qt.rgba(1, 1, 1, 0.12) : "#E3E8E6"
    // The rail layout has no top bar, so the page shows its own title there.
    readonly property bool showTitle: ApplicationWindow.window !== null
                                      && ApplicationWindow.window.railLayout === true
    readonly property string sourceUrl: "https://github.com/abuhelalah/CloakQR"

    background: Rectangle {
        color: page.canvasColor
    }

    // A ticked line in the privacy card.
    component CheckLine: RowLayout {
        property alias text: checkLabel.text
        Layout.fillWidth: true
        spacing: 12
        SvgIcon {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 1
            source: "qrc:/icons/check.svg"
            color: page.primaryColor
            size: 20
        }
        Label {
            id: checkLabel
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 15
            lineHeight: 1.2
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(page.width, page.wideLayout ? 640 : 600)
            x: Math.max(0, (page.width - width) / 2)
            spacing: 16

            Label {
                visible: page.showTitle
                Layout.leftMargin: page.sideMargin
                Layout.topMargin: 28
                text: qsTr("About")
                font.pixelSize: Math.round(28 * appSettings.fontScale)
                font.bold: true
            }

            // --- Identity ----------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: page.showTitle ? 8 : 32
                Layout.bottomMargin: 8
                spacing: 10

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    // Light-tile lockup on dark backgrounds, per the brand sheet.
                    source: Material.theme === Material.Dark ? "qrc:/images/logo_on_dark.svg" : "qrc:/images/logo.svg"
                    sourceSize: Qt.size(100, 100)
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 100
                    Accessible.role: Accessible.Graphic
                    Accessible.name: qsTr("CloakQR logo")
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: appEngine.paidEdition ? qsTr("CloakQR Pro") : qsTr("CloakQR")
                    font.pixelSize: 26
                    font.bold: true
                }
                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: page.sideMargin
                    Layout.rightMargin: page.sideMargin
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Private by design") + " · " + qsTr("Version %1").arg(appEngine.version)
                    color: page.mutedColor
                    font.pixelSize: 15
                }
            }

            // --- Privacy statement -------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.sideMargin
                Layout.rightMargin: page.sideMargin
                implicitHeight: privacyColumn.implicitHeight + 36
                radius: 20
                color: page.surfaceColor

                ColumnLayout {
                    id: privacyColumn
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Everything runs on your device")
                        font.pixelSize: 16
                        font.bold: true
                        color: page.primaryColor
                    }
                    CheckLine { text: qsTr("No accounts, no tracking, no network access") }
                    CheckLine { text: qsTr("Scanning and creating happen locally") }
                    CheckLine { text: qsTr("History stays on this device and is never uploaded") }
                }
            }

            // --- Source & licence --------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.sideMargin
                Layout.rightMargin: page.sideMargin
                Layout.bottomMargin: 28
                implicitHeight: linksColumn.implicitHeight
                radius: 20
                color: page.surfaceColor

                ColumnLayout {
                    id: linksColumn
                    anchors.fill: parent
                    spacing: 0

                    ItemDelegate {
                        Layout.fillWidth: true
                        leftPadding: 18
                        rightPadding: 18
                        topPadding: 16
                        bottomPadding: 16
                        Accessible.role: Accessible.Link
                        Accessible.name: qsTr("CloakQR source code on GitHub")
                        onClicked: Qt.openUrlExternally(page.sourceUrl)
                        background: Item {}
                        contentItem: RowLayout {
                            spacing: 14
                            SvgIcon {
                                source: "qrc:/icons/code.svg"
                                color: page.primaryColor
                                size: 22
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Source code & issues")
                                    font.pixelSize: 16
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: "github.com/abuhelalah/CloakQR"
                                    color: page.mutedColor
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                            }
                            SvgIcon {
                                source: "qrc:/icons/external.svg"
                                color: page.mutedColor
                                size: 20
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 18
                        Layout.rightMargin: 18
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 18
                        Layout.topMargin: 16
                        Layout.bottomMargin: 16
                        spacing: 14
                        SvgIcon {
                            source: "qrc:/icons/file.svg"
                            color: page.primaryColor
                            size: 22
                        }
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("License")
                            font.pixelSize: 16
                        }
                        Label {
                            text: "MPL-2.0"
                            color: page.mutedColor
                            font.pixelSize: 14
                            Accessible.name: qsTr("Released under the Mozilla Public License 2.0.")
                        }
                    }
                }
            }
        }
    }
}
