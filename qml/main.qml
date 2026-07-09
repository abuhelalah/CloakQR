import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CloakQR.Common 1.0
import CloakQR.Views 1.0

ApplicationWindow {
    id: root
    width: 420
    height: 860
    visible: true
    title: "CloakQR"

    function previewHost(url) {
        const match = url.match(/^https?:\/\/([^/?#]+)/i)
        return match ? match[1] : ""
    }

    SafePreviewDialog {
        id: safePreviewDialog
    }

    Connections {
        target: qrDecoder

        function onUrlDetected(url) {
            safePreviewDialog.rawUrl = url
            safePreviewDialog.host = root.previewHost(url)
            safePreviewDialog.open()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Header {
            Layout.fillWidth: true
            title: "CloakQR"
            subtitle: "Offline and private"
        }

        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: ScannerPage {}
        }

        Footer {
            Layout.fillWidth: true
            leftText: "Local only"
            centerText: "No tracking"
            rightText: "v0.1"
        }
    }
}
