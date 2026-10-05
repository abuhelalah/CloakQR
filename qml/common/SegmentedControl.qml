import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Outlined pill with equal-width segments; the selected one gets a tonal fill.
// `model` is a list of { key, label }; `currentKey` is the selected key.
Rectangle {
    id: control
    property var model: []
    property string currentKey: ""
    property color fillColor: "#FFFFFF"
    property color selectedColor: "#D5EBE4"
    property color selectedTextColor: "#053B33"
    property color textColor: "#4B5754"
    signal activated(string key)

    implicitHeight: 44
    radius: height / 2
    color: control.fillColor
    border.width: 1
    border.color: "#8A9693"

    RowLayout {
        anchors.fill: parent
        anchors.margins: 1
        spacing: 0

        Repeater {
            model: control.model
            delegate: AbstractButton {
                id: segment
                required property var modelData
                required property int index
                readonly property bool selected: control.currentKey === modelData.key
                readonly property bool first: index === 0
                readonly property bool last: index === control.model.length - 1
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1 // equal widths
                checkable: true
                checked: selected
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData.label
                onClicked: control.activated(modelData.key)

                // Outer segments round only their outer side.
                background: Item {
                    visible: segment.selected
                    Rectangle {
                        anchors.fill: parent
                        radius: (segment.first || segment.last) ? height / 2 : 0
                        color: control.selectedColor
                    }
                    // Squares off the inner side. Anchors (unlike x) follow
                    // LayoutMirroring, so this stays correct in RTL.
                    Rectangle {
                        visible: segment.first !== segment.last
                        width: parent.width / 2
                        height: parent.height
                        anchors.right: segment.first ? parent.right : undefined
                        anchors.left: segment.last ? parent.left : undefined
                        color: control.selectedColor
                    }
                }
                contentItem: Label {
                    text: segment.modelData.label
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    // Long labels (e.g. Arabic) wrap to two lines and shrink a
                    // little to fit, rather than being cut off.
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    lineHeight: 0.9
                    leftPadding: 4
                    rightPadding: 4
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 10
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: segment.selected ? control.selectedTextColor : control.textColor
                }
            }
        }
    }
}
