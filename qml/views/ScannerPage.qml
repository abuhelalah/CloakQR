import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtQuick.Layouts
import QtMultimedia

Page {
    id: page
    title: qsTr("Scanner")
    property bool wideLayout: false
    property color canvasColor: "#F3F7F5"
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#086C5C"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#5D6F69"
    property color accentColor: "#C84F2D"
    property string statusMessage: qsTr("Ready to scan")
    property bool cameraRequested: false
    property bool imageDecoding: false
    property bool torchOn: false
    readonly property bool useNativePicker: Qt.platform.os === "android"
                                            || Qt.platform.os === "ios"

    // Classifies a scanned payload into the same categories the scan result
    // dialog recognises, so history entries show a meaningful icon. The order
    // mirrors SafePreviewDialog's recogniser table (deep links before URLs).
    function classifyType(text) {
        if (/^WIFI:/i.test(text)) return "wifi"
        if (/^(mailto:|MATMSG:)/i.test(text)) return "email"
        if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(text)) return "email"
        if (/^tel:/i.test(text)) return "tel"
        if (/^(sms|smsto):/i.test(text)) return "sms"
        if (/^geo:/i.test(text)) return "geo"
        if (/^(BEGIN:VCARD|MECARD:)/i.test(text)) return "vcard"
        if (/^otpauth:\/\//i.test(text)) return "otp"
        if (/^BEGIN:VCALENDAR/i.test(text)) return "calendar"
        if (/^BCD\r?\n/.test(text)) return "sepa"
        if (/^whatsapp:\/\//i.test(text)) return "whatsapp"
        if (/^https:\/\/(wa\.me|api\.whatsapp\.com)\//i.test(text)) return "whatsapp"
        if (/^tg:\/\//i.test(text)) return "telegram"
        if (/^https:\/\/t\.me\//i.test(text)) return "telegram"
        if (/^sgnl:\/\//i.test(text)) return "signal"
        if (/^https:\/\/signal\.me\//i.test(text)) return "signal"
        if (/^facetime(-audio)?:/i.test(text)) return "facetime"
        if (/^fb-messenger:\/\//i.test(text)) return "messenger"
        if (/^bitcoin:/i.test(text)) return "bitcoin"
        if (/^ethereum:/i.test(text)) return "ethereum"
        if (/^upi:\/\//i.test(text)) return "upi"
        if (/^https:\/\/(www\.)?paypal\.me\//i.test(text)) return "paypal"
        if (/^market:\/\//i.test(text)) return "store"
        if (/^https?:\/\/(play\.google\.com|apps\.apple\.com|itunes\.apple\.com)\//i.test(text)) return "store"
        if (/^https?:\/\//i.test(text)) return "url"
        if (/^ENC:1/i.test(text)) return "encrypted"
        return "text"
    }

    // Largest square camera preview that still leaves room for the header,
    // buttons and privacy note, so the page fits without scrolling on tablets
    // (portrait and landscape) and phones alike.
    readonly property real previewSize: {
        var widthCap = Math.min(page.width - (page.wideLayout ? 64 : 40),
                                page.wideLayout ? 520 : 360)
        var heightCap = page.height - (page.wideLayout ? 320 : 380)
        return Math.max(200, Math.min(widthCap, heightCap))
    }

    function startCamera() {
        if (mediaDevices.videoInputs.length === 0) {
            page.cameraRequested = false
            page.statusMessage = qsTr("No camera was found")
            return
        }
        page.cameraRequested = true
        page.statusMessage = qsTr("Point the camera at a QR code")
        camera.active = true
    }

    function stopCamera() {
        page.cameraRequested = false
        if (page.torchOn) {
            page.torchOn = false
            camera.torchMode = Camera.TorchOff
        }
        camera.active = false
    }

    function decodeImageAt(url) {
        page.imageDecoding = true
        page.statusMessage = qsTr("Scanning image\u2026")
        qrDecoder.decodeImageFile(url)
    }

    CameraPermission {
        id: cameraPermission
        onStatusChanged: {
            if (status === Qt.PermissionStatus.Granted) {
                page.startCamera()
            } else if (status === Qt.PermissionStatus.Denied) {
                page.cameraRequested = false
                page.statusMessage = qsTr("Camera permission was denied")
            }
        }
    }

    MediaDevices {
        id: mediaDevices
    }

    Camera {
        id: camera
        cameraDevice: mediaDevices.defaultVideoInput
        onErrorOccurred: function(error, errorString) {
            page.stopCamera()
            page.statusMessage = errorString
        }
    }

    CaptureSession {
        camera: camera
        videoOutput: cameraOutput
    }

    // Mobile uses the platform's native storage picker.
    FileDialog {
        id: imageDialog
        title: qsTr("Choose a QR code image")
        fileMode: FileDialog.OpenFile
        nameFilters: [qsTr("Images (*.png *.jpg *.jpeg *.bmp *.webp)")]
        onAccepted: page.decodeImageAt(selectedFile)
    }

    // Desktop uses an in-app, Material-themed picker that follows the theme.
    FilePickerDialog {
        id: imagePicker
        dialogTitle: qsTr("Choose a QR code image")
        patterns: ["*.png", "*.jpg", "*.jpeg", "*.bmp", "*.webp"]
        primaryColor: page.primaryColor
        primaryTextColor: page.primaryTextColor
        mutedColor: page.mutedColor
        onAccepted: (file) => page.decodeImageAt(file)
    }

    Connections {
        target: qrDecoder

        function onDecodeSucceeded(text) {
            page.imageDecoding = false
            page.stopCamera()
            page.statusMessage = qsTr("QR code detected")
            const excludedWifi = appSettings.historyExcludeWifiPassword
                                 && text.startsWith("WIFI:")
            if (appSettings.historyEnabled && !excludedWifi)
                scanHistory.addEntry(text, page.classifyType(text))
        }

        function onDecodeFailed(reason) {
            page.imageDecoding = false
            page.statusMessage = reason
        }
    }

    Component.onCompleted: qrDecoder.setVideoSink(cameraOutput.videoSink)
    Component.onDestruction: {
        page.stopCamera()
        qrDecoder.setVideoSink(null)
    }

    background: Rectangle {
        color: page.canvasColor
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(page.width, page.wideLayout ? 920 : 560)
            x: Math.max(0, (page.width - width) / 2)
            spacing: 20

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 32 : 20
                Layout.rightMargin: page.wideLayout ? 32 : 20
                Layout.topMargin: page.wideLayout ? 32 : 20
                spacing: 4

                Label {
                    text: qsTr("Scan a QR code")
                    font.pixelSize: page.wideLayout ? 28 : 23
                    font.bold: true
                }
                Label {
                    text: qsTr("Point your camera at a code or choose an image")
                    color: page.mutedColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: page.previewSize
                Layout.preferredHeight: page.previewSize
                radius: 8
                color: page.surfaceColor
                border.color: page.primaryColor
                border.width: 2

                VideoOutput {
                    id: cameraOutput
                    anchors.fill: parent
                    anchors.margins: 2
                    visible: page.cameraRequested
                    fillMode: VideoOutput.PreserveAspectCrop
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.7
                    height: width
                    color: "transparent"
                    border.color: page.primaryColor
                    border.width: 3
                    radius: 8
                    z: 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - 24
                        height: 2
                        color: page.accentColor
                        opacity: 0.85
                    }
                }

                Rectangle {
                    id: statusPill
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    width: Math.min(parent.width - 24, statusLabel.implicitWidth + 24)
                    height: statusLabel.implicitHeight + 12
                    radius: height / 2
                    color: Qt.rgba(0, 0, 0, 0.55)
                    z: 2

                    Label {
                        id: statusLabel
                        anchors.centerIn: parent
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: page.cameraRequested ? qsTr("Scanning…") : page.statusMessage
                        color: "#FFFFFF"
                    }
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    running: page.imageDecoding
                    visible: running
                    z: 3
                }

                // Flashlight toggle; only offered when the camera is live and
                // reports torch support so we never show a dead control.
                Button {
                    id: torchButton
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    z: 3
                    implicitWidth: 44
                    implicitHeight: 44
                    visible: page.cameraRequested && camera.active
                             && camera.isTorchModeSupported(Camera.TorchOn)
                    Accessible.name: page.torchOn
                        ? qsTr("Turn off flashlight")
                        : qsTr("Turn on flashlight")
                    onClicked: {
                        page.torchOn = !page.torchOn
                        camera.torchMode = page.torchOn ? Camera.TorchOn : Camera.TorchOff
                    }

                    contentItem: Label {
                        text: "🔦"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: width / 2
                        color: page.torchOn ? page.primaryColor
                            : Qt.rgba(0, 0, 0, 0.35)
                        border.width: 1
                        border.color: page.torchOn
                            ? page.primaryColor
                            : Qt.rgba(1, 1, 1, 0.35)
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 32 : 20
                Layout.rightMargin: page.wideLayout ? 32 : 20
                columns: page.wideLayout ? 2 : 1
                columnSpacing: 12
                rowSpacing: 10

                Button {
                    Layout.fillWidth: true
                    text: page.cameraRequested ? qsTr("Close camera") : qsTr("Open camera")
                    Material.background: page.primaryColor
                    Material.foreground: page.primaryTextColor
                    Accessible.name: text
                    onClicked: {
                        if (page.cameraRequested) {
                            page.stopCamera()
                            page.statusMessage = qsTr("Camera closed")
                        } else if (cameraPermission.status === Qt.PermissionStatus.Granted) {
                            page.startCamera()
                        } else {
                            cameraPermission.request()
                        }
                    }
                }
                Button {
                    Layout.fillWidth: true
                    text: qsTr("Choose image")
                    enabled: !page.imageDecoding
                    Accessible.name: qsTr("Choose image")
                    onClicked: {
                        page.stopCamera()
                        if (page.useNativePicker)
                            imageDialog.open()
                        else
                            imagePicker.openAt(StandardPaths.writableLocation(
                                                   StandardPaths.PicturesLocation))
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 32 : 20
                Layout.rightMargin: page.wideLayout ? 32 : 20
                Layout.bottomMargin: 24
                implicitHeight: privacyRow.implicitHeight + 24
                radius: 8
                color: page.surfaceColor

                RowLayout {
                    id: privacyRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 9
                        Layout.preferredHeight: 9
                        radius: 5
                        color: page.primaryColor
                    }
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Scanning stays on this device")
                        color: page.mutedColor
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
