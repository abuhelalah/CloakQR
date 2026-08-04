import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: page
    title: qsTr("About")
    property bool wideLayout: false
    property color canvasColor: "#F3F7F5"
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#086C5C"
    property color mutedColor: "#5D6F69"

    background: Rectangle {
        color: page.canvasColor
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(page.width, page.wideLayout ? 760 : 600)
            x: Math.max(0, (page.width - width) / 2)
            spacing: 12

            Label {
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: page.wideLayout ? 28 : 20
                text: qsTr("About")
                font.pixelSize: page.wideLayout ? 28 : 23
                font.bold: true
            }

            // --- Identity ----------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                spacing: 16

                Image {
                    source: "qrc:/images/Logo_QR_icon.png"
                    sourceSize.width: 64
                    sourceSize.height: 64
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64
                    fillMode: Image.PreserveAspectFit
                    Accessible.role: Accessible.Graphic
                    Accessible.name: qsTr("CloakQR logo")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: appEngine.paidEdition ? qsTr("CloakQR Pro") : qsTr("CloakQR")
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Label {
                        text: qsTr("Private by design")
                        color: page.mutedColor
                    }
                    Label {
                        text: qsTr("Version %1").arg(appEngine.version)
                        color: page.mutedColor
                        font.pixelSize: 12
                    }
                }
            }

            // --- Privacy statement -------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: 8
                implicitHeight: privacyColumn.implicitHeight + 28
                radius: 12
                color: page.surfaceColor

                ColumnLayout {
                    id: privacyColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label {
                        text: qsTr("Everything runs on your device")
                        font.bold: true
                        color: page.primaryColor
                    }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Scanning and creating QR codes happen entirely on your device — no accounts, no tracking, and no network access.")
                    }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: qsTr("Your scan history is stored locally and is never uploaded.")
                    }
                }
            }

            // --- Source ------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: 8
                implicitHeight: sourceColumn.implicitHeight + 28
                radius: 12
                color: page.surfaceColor

                ColumnLayout {
                    id: sourceColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Label {
                        text: qsTr("Open source")
                        font.bold: true
                        color: page.primaryColor
                    }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        textFormat: Text.StyledText
                        linkColor: page.primaryColor
                        text: qsTr("View the source code and report issues on <a href=\"https://github.com/abuhelalah/CloakQR\">github.com/abuhelalah/CloakQR</a>.")
                        onLinkActivated: (link) => Qt.openUrl(link)
                        Accessible.role: Accessible.Link
                        Accessible.name: qsTr("CloakQR source code on GitHub")
                    }
                }
            }

            // --- Licence -----------------------------------------------------
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.bottomMargin: 24
                wrapMode: Text.WordWrap
                color: page.mutedColor
                font.pixelSize: 12
                text: qsTr("Released under the Mozilla Public License 2.0.")
            }
        }
    }
}
