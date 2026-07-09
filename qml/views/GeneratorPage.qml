import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: "Generator"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        TextField {
            id: inputText
            Layout.fillWidth: true
            placeholderText: "Enter content"
        }

        Button {
            text: "Generate"
            onClicked: qrGenerator.generateQr(inputText.text)
        }
    }
}
