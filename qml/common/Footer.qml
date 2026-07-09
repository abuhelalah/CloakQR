import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: 56
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined

    property color backgroundColor: "#111827"
    property color textColor: "#D1D5DB"
    property string leftText: ""
    property string centerText: ""
    property string rightText: ""

    Rectangle {
        anchors.fill: parent
        color: root.backgroundColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Label {
            text: root.leftText
            color: root.textColor
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Label {
            text: root.centerText
            color: root.textColor
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Label {
            text: root.rightText
            color: root.textColor
            horizontalAlignment: Text.AlignRight
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
