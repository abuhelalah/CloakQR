import QtQuick
import QtQuick.Controls

Page {
    title: "Scanner"

    Column {
        anchors.centerIn: parent
        spacing: 12

        Label { text: "Scanner view placeholder" }
        Button {
            text: "Simulate URL"
            onClicked: qrDecoder.handleDecodedText("https://example.com")
        }
    }
}
