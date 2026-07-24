import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: qsTr("Scanner")

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Label {
            text: qsTr("Scanner view placeholder")
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            text: qsTr("Simulate URL scan")
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                qrDecoder.handleDecodedText("https://example.com")
                scanHistory.addEntry("https://example.com", "url")
            }
        }

        Button {
            text: qsTr("Simulate text scan")
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                qrDecoder.handleDecodedText("Hello, CloakQR!")
                scanHistory.addEntry("Hello, CloakQR!", "text")
            }
        }
    }
}
