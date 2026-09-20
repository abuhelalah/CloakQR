import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// A text input with a paste button on the right. Pasting only affects this
// field, so each field in a form carries its own paste affordance.
RowLayout {
    id: root
    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property alias echoMode: field.echoMode
    property alias inputMethodHints: field.inputMethodHints
    property string accessibleName: ""
    signal changed()

    spacing: 6

    TextField {
        id: field
        Layout.fillWidth: true
        Accessible.name: root.accessibleName
        onTextChanged: root.changed()
    }

    function clear() {
        field.clear()
    }

    ToolButton {
        implicitWidth: 40
        implicitHeight: 40
        Accessible.name: qsTr("Paste from clipboard")
        Accessible.role: Accessible.Button
        onClicked: field.paste()

        contentItem: SvgIcon {
            source: "qrc:/icons/paste.svg"
            color: Material.foreground
            size: 18
        }
        background: Rectangle {
            radius: 8
            color: "transparent"
        }
    }
}
