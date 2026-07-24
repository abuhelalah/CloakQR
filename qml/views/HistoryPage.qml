import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    title: qsTr("History")

    ListView {
        id: historyList
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6
        model: scanHistory

        delegate: ItemDelegate {
            width: historyList.width

            function typeIcon(type) {
                if (type === "url") return "🔗"
                if (type === "encrypted") return "🔒"
                return "📄"
            }

            contentItem: ColumnLayout {
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: typeIcon(model.contentType)
                        font.pixelSize: 16
                    }

                    Label {
                        text: model.content
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: 14
                    }
                }

                Label {
                    text: model.timestamp
                    font.pixelSize: 11
                    opacity: 0.6
                }
            }
        }

        Label {
            anchors.centerIn: parent
            visible: historyList.count === 0
            text: qsTr("No scans yet")
            opacity: 0.5
        }
    }

    footer: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.margins: 4

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Clear")
                enabled: historyList.count > 0
                onClicked: scanHistory.clear()
            }
        }
    }
}
