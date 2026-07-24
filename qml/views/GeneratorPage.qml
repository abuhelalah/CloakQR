import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: qsTr("Generator")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        TextField {
            id: inputText
            Layout.fillWidth: true
            placeholderText: qsTr("Enter content")
        }

        Button {
            text: qsTr("Generate")
            Layout.fillWidth: true
            enabled: inputText.text.length > 0
            onClicked: qrImage.source = "image://qrcode/" + encodeURIComponent(inputText.text)
        }

        Image {
            id: qrImage
            Layout.alignment: Qt.AlignHCenter
            width: 256
            height: 256
            fillMode: Image.PreserveAspectFit
            visible: source.toString().length > 0
        }
    }
}
