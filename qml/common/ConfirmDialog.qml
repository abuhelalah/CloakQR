import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Reusable confirmation prompt with a heading, message and Cancel / destructive
// action buttons, themed automatically by the Material style.
Dialog {
    id: dialog

    property string heading: qsTr("Are you sure?")
    property string message: ""
    property string confirmText: qsTr("Delete")
    property color dangerColor: "#D32F2F"

    signal confirmed()

    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    modal: true
    dim: true
    padding: 20
    width: Math.min(420, (Overlay.overlay ? Overlay.overlay.width : 420) - 48)

    contentItem: ColumnLayout {
        spacing: 14

        Label {
            Layout.fillWidth: true
            text: dialog.heading
            font.bold: true
            font.pixelSize: 17
        }

        Label {
            Layout.fillWidth: true
            text: dialog.message
            wrapMode: Text.WordWrap
            opacity: 0.8
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 10

            Item { Layout.fillWidth: true }

            Button {
                flat: true
                text: qsTr("Cancel")
                Accessible.name: text
                onClicked: dialog.close()
            }

            Button {
                text: dialog.confirmText
                Accessible.name: text
                Material.background: dialog.dangerColor
                Material.foreground: "#FFFFFF"
                onClicked: {
                    dialog.confirmed()
                    dialog.close()
                }
            }
        }
    }
}
