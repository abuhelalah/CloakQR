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

    // Idle-landing hint: the camera starts on an explicit gesture, never on tab
    // open. Wording differs between touch and pointer platforms.
    readonly property string activateHint:
        (Qt.platform.os === "android" || Qt.platform.os === "ios")
            ? qsTr("Double-tap to activate camera")
            : qsTr("Double-click to activate camera")
    property bool idleError: false
    property string idleErrorMessage: ""
    readonly property string idleHint: page.idleError ? page.idleErrorMessage : page.activateHint
    readonly property string closeHint:
        (Qt.platform.os === "android" || Qt.platform.os === "ios")
            ? qsTr("Double-tap to close camera")
            : qsTr("Double-click to close camera")

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

    // Reticle size on the idle landing. It reserves room for the hint, the
    // "Choose image" button and the privacy badge below it so those elements
    // can never overlap when the window is short (landscape tablet / resized
    // desktop window).
    readonly property real idleFrameSize: {
        var widthCap = Math.min(page.width - 32, page.wideLayout ? 520 : 420)
        var heightCap = page.height - 210
        return Math.max(140, Math.min(widthCap, heightCap))
    }

    function startCamera() {
        if (mediaDevices.videoInputs.length === 0) {
            page.cameraRequested = false
            page.statusMessage = qsTr("No camera was found")
            return
        }
        page.cameraRequested = true
        page.statusMessage = qsTr("Align QR code in frame")
        camera.active = true
    }

    function stopCamera() {
        page.cameraRequested = false
        if (page.torchOn) {
            page.torchOn = false
            camera.torchMode = Camera.TorchOff
        }
        camera.active = false
        page.idleError = false
    }

    function decodeImageAt(url) {
        page.imageDecoding = true
        page.statusMessage = qsTr("Scanning image\u2026")
        qrDecoder.decodeImageFile(url)
    }

    function chooseImage() {
        page.stopCamera()
        if (page.useNativePicker)
            imageDialog.open()
        else
            imagePicker.openAt(StandardPaths.writableLocation(
                                   StandardPaths.PicturesLocation))
    }

    // Activates the camera after an explicit gesture (double-tap/double-click,
    // or a single tap on the reticle). Permission is requested on first use.
    function activate() {
        if (mediaDevices.videoInputs.length === 0) {
            page.idleError = true
            page.idleErrorMessage = qsTr("No camera was found")
            return
        }
        if (cameraPermission.status === Qt.PermissionStatus.Granted)
            page.startCamera()
        else if (cameraPermission.status === Qt.PermissionStatus.Denied) {
            page.idleError = true
            page.idleErrorMessage = qsTr("Camera permission was denied")
        } else {
            cameraPermission.request()
        }
    }

    CameraPermission {
        id: cameraPermission
        onStatusChanged: {
            if (status === Qt.PermissionStatus.Granted) {
                page.startCamera()
            } else if (status === Qt.PermissionStatus.Denied) {
                page.idleError = true
                page.idleErrorMessage = qsTr("Camera permission was denied")
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
        onTorchModeChanged: {
            // Some devices (legacy camera HAL) can't sustain the torch while
            // the preview streams, so the HAL silently reverts it. Keep the
            // button state honest instead of showing a stale "on" fill.
            if (page.torchOn && camera.torchMode !== Camera.TorchOn)
                page.torchOn = false
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

    Component.onCompleted: {
        qrDecoder.setVideoSink(cameraOutput.videoSink)
    }
    Component.onDestruction: {
        page.stopCamera()
        qrDecoder.setVideoSink(null)
    }
    onVisibleChanged: {
        if (!visible)
            page.stopCamera()
    }

    background: Rectangle {
        color: page.canvasColor
    }

    // Idle landing: no camera runs until the user explicitly activates it.
    Rectangle {
        id: idleSurface
        anchors.fill: parent
        visible: !page.cameraRequested
        color: "transparent"

        // Double-tap / double-click anywhere on the surface activates.
        TapHandler {
            onDoubleTapped: page.activate()
        }

        // The idle landing is a single ColumnLayout so the reticle, hint,
        // button and privacy badge flow from top to bottom and can never
        // overlap each other, whatever the window size.
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 16
            anchors.bottomMargin: 12
            spacing: 0

            Item { Layout.fillHeight: true }

            // Reticle (static; no live feed yet).
            Rectangle {
                id: idleFrame
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: page.idleFrameSize
                Layout.preferredHeight: page.idleFrameSize
                color: "transparent"
                border.color: page.primaryColor
                border.width: 3
                radius: 12

                // Single tap on the reticle is a fallback activation path.
                TapHandler {
                    onSingleTapped: page.activate()
                }
            }

            ColumnLayout {
                id: idleHintColumn
                Layout.fillWidth: true
                Layout.topMargin: 20
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: 480
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Align QR code in frame")
                    color: Material.foreground
                    font.pixelSize: 13
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: page.idleHint
                    color: page.primaryColor
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
            }

            // Choose an image directly, without activating the camera.
            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 18
                enabled: !page.imageDecoding
                Material.background: page.primaryColor
                Accessible.name: qsTr("Choose image")
                onClicked: page.chooseImage()

                contentItem: Row {
                    anchors.centerIn: parent
                    spacing: 8
                    SvgIcon {
                        source: "qrc:/icons/image.svg"
                        color: page.primaryTextColor
                        size: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        text: qsTr("Choose image")
                        color: page.primaryTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Local-only badge.
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 4
                width: idlePrivacyLabel.implicitWidth + 28
                height: idlePrivacyLabel.implicitHeight + 12
                radius: height / 2
                color: Qt.rgba(page.primaryColor.r, page.primaryColor.g, page.primaryColor.b, 0.10)
                border.width: 1
                border.color: Qt.rgba(page.primaryColor.r, page.primaryColor.g, page.primaryColor.b, 0.30)

                Label {
                    id: idlePrivacyLabel
                    anchors.centerIn: parent
                    text: qsTr("No data tracking · 100% local")
                    color: page.primaryColor
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: page.imageDecoding
            visible: running
            z: 2
        }
    }

    // Full-bleed live camera (the normal state of the Scan tab).
    Rectangle {
        anchors.fill: parent
        visible: page.cameraRequested
        color: "#000000"

        VideoOutput {
            id: cameraOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
        }

        // Double-tap / double-click anywhere on the live view deactivates.
        TapHandler {
            onDoubleTapped: page.stopCamera()
        }

        // "Secure scan active" pill.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 14
            width: secureLabel.implicitWidth + 26
            height: secureLabel.implicitHeight + 12
            radius: height / 2
            color: Qt.rgba(page.primaryColor.r, page.primaryColor.g, page.primaryColor.b, 0.16)
            border.width: 1
            border.color: page.primaryColor

            Label {
                id: secureLabel
                anchors.centerIn: parent
                text: qsTr("Secure scan active")
                color: page.primaryColor
                font.pixelSize: 12
                font.bold: true
            }
        }

        // Scan frame with an animated sweep line.
        Rectangle {
            id: scanFrame
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -30
            width: Math.min(parent.width, parent.height) * 0.72
            height: width
            color: "transparent"
            border.color: page.primaryColor
            border.width: 3
            radius: 12
            clip: true

            Rectangle {
                id: scanLine
                width: parent.width
                height: 2
                color: page.accentColor
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: page.cameraRequested && camera.active
                    NumberAnimation { from: 4; to: scanFrame.height - 6; duration: 1700; easing.type: Easing.InOutSine }
                    NumberAnimation { from: scanFrame.height - 6; to: 4; duration: 1700; easing.type: Easing.InOutSine }
                }
            }
        }

        // Scan hint / status line.
        Label {
            id: activeStatusLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: scanFrame.bottom
            anchors.topMargin: 16
            text: page.statusMessage.length > 0 ? page.statusMessage : qsTr("Align QR code in frame")
            color: "#FFFFFF"
            font.pixelSize: 13
            opacity: 0.92
        }

        // How to exit the live view.
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: activeStatusLabel.bottom
            anchors.topMargin: 6
            text: page.closeHint
            color: page.mutedColor
            font.pixelSize: 12
            opacity: 0.9
        }

        // Privacy badge.
        Rectangle {
            id: privacyBadge
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            width: privacyLabel.implicitWidth + 28
            height: privacyLabel.implicitHeight + 12
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.45)

            Label {
                id: privacyLabel
                anchors.centerIn: parent
                text: qsTr("No data tracking · 100% local")
                color: page.primaryColor
                font.pixelSize: 12
                font.bold: true
            }
        }

        // Flashlight toggle; only offered when the camera reports torch support.
        Button {
            id: torchButton
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: privacyBadge.top
            anchors.bottomMargin: 18
            width: 68
            height: 68
            padding: 0
            visible: camera.active && camera.isTorchModeSupported(Camera.TorchOn)
            Accessible.name: page.torchOn
                ? qsTr("Turn off flashlight")
                : qsTr("Turn on flashlight")
            onClicked: {
                page.torchOn = !page.torchOn
                camera.torchMode = page.torchOn ? Camera.TorchOn : Camera.TorchOff
            }

            contentItem: Item {
                anchors.fill: parent // Forces this container to take up the full 68x68 area

                // A white halo behind the bolt keeps the dark icon legible even
                // on dark camera scenes, while the dark bolt reads on bright ones.
                SvgIcon {
                    anchors.centerIn: parent // Now properly centers in the 68x68 area
                    source: "qrc:/icons/flash.svg"
                    color: "#FFFFFF"
                    size: 28
                }
                SvgIcon {
                    anchors.centerIn: parent
                    source: "qrc:/icons/flash.svg"
                    color: "#161616"
                    size: 28
                }
            }
            background: Rectangle {
                anchors.fill: parent
                radius: width / 2 // Since width == height, this creates a perfect circle

                // Translucent white (35% off / 70% on) so the camera feed shows
                // through the circle; the fill brightens when the torch is on.
                color: page.torchOn
                    ? Qt.rgba(1, 1, 1, 0.70)
                    : Qt.rgba(1, 1, 1, 0.35)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.50)
            }
        }
    }
}
