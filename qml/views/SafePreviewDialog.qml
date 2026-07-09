import QtQuick
import QtQuick.Controls

Dialog {
    id: dialog
    modal: true
    title: "Safe Preview"

    property string rawUrl: ""
    property string host: ""

    onAccepted: Qt.openUrlExternally(rawUrl)

    Column {
        spacing: 8
        width: 320

        Label { text: "Host: " + dialog.host; wrapMode: Text.Wrap }
        Label { text: dialog.rawUrl; wrapMode: Text.Wrap }
    }

    standardButtons: Dialog.Open | Dialog.Cancel
}
