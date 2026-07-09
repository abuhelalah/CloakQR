import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: 64
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined

    property alias title: titleLabel.text
    property string subtitle: ""
    property color backgroundColor: "#111827"
    property color titleColor: "#F9FAFB"
    property color subtitleColor: "#9CA3AF"
    property bool showBackButton: false
    property string backText: "Back"
    signal backClicked()

    Rectangle {
        anchors.fill: parent
        color: root.backgroundColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        Button {
            id: backButton
            visible: root.showBackButton
            text: root.backText
            onClicked: root.backClicked()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Label {
                id: titleLabel
                text: "App Title"
                color: root.titleColor
                font.pixelSize: 18
                font.bold: true
                elide: Text.ElideRight
            }

            Label {
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: root.subtitleColor
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }
}
