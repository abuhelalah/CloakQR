import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// A labelled, outlined text input with paste and clear buttons inside it.
// Pasting only affects this field, so each field in a form carries its own
// paste affordance. The label defaults to the accessible name.
ColumnLayout {
    id: root
    property alias text: field.text
    property string placeholderText: ""
    property alias echoMode: field.echoMode
    property alias inputMethodHints: field.inputMethodHints
    property string accessibleName: ""
    property string label: accessibleName
    property color fillColor: "#FFFFFF"
    property color mutedColor: "#4B5754"
    // Hides the paste/clear buttons on short fields (e.g. a country code).
    property bool showActions: true
    signal changed()

    spacing: 6

    function clear() {
        field.clear()
    }

    Label {
        Layout.fillWidth: true
        visible: root.label.length > 0
        text: root.label
        color: root.mutedColor
        font.pixelSize: 13
        font.weight: Font.Medium
        elide: Text.ElideRight
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 56
        radius: 14
        color: root.fillColor
        border.width: field.activeFocus ? 2 : 1
        border.color: field.activeFocus ? root.Material.accent : "#8A9693"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: root.showActions ? 4 : 12
            spacing: 0

            TextField {
                id: field
                Layout.fillWidth: true
                Accessible.name: root.accessibleName
                font.pixelSize: 16
                leftPadding: 0
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
                background: null
                // Material floats the placeholder over typed text; show it
                // only while the field is empty (the label sits above).
                placeholderText: text.length > 0 ? "" : root.placeholderText
                verticalAlignment: TextInput.AlignVCenter
                onTextChanged: root.changed()
            }

            ToolButton {
                implicitWidth: 44
                implicitHeight: 44
                visible: root.showActions
                Accessible.name: qsTr("Paste from clipboard")
                Accessible.role: Accessible.Button
                onClicked: field.paste()
                contentItem: Item {
                    SvgIcon {
                        anchors.centerIn: parent
                        source: "qrc:/icons/paste.svg"
                        color: root.mutedColor
                        size: 20
                    }
                }
            }

            ToolButton {
                implicitWidth: 44
                implicitHeight: 44
                visible: root.showActions && field.text.length > 0
                Accessible.name: qsTr("Clear")
                Accessible.role: Accessible.Button
                onClicked: field.clear()
                contentItem: Item {
                    SvgIcon {
                        anchors.centerIn: parent
                        source: "qrc:/icons/close_circle.svg"
                        color: root.mutedColor
                        size: 20
                    }
                }
            }
        }
    }
}
