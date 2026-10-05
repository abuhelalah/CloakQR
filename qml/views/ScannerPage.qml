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
    property color canvasColor: "#F1F5F3"
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#0B6B5E"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#4B5754"
    property color accentColor: "#C84F2D"
    // Tonal colours for the camera-off badge and the privacy pill.
    property color containerColor: "#D5EBE4"
    property color containerTextColor: "#053B33"
    property color errorColor: "#B3261E"
    property bool cameraRequested: false
    property bool imageDecoding: false
    property bool torchOn: false
    readonly property bool useNativePicker: Qt.platform.os === "android"
                                            || Qt.platform.os === "ios"

    // Last camera/permission/image error, shown in place of the hint line.
    property string errorMessage: ""
    readonly property string hint: page.errorMessage.length > 0 ? page.errorMessage
                                   : page.imageDecoding ? qsTr("Scanning image\u2026")
                                   : page.cameraRequested ? qsTr("Hold steady \u2014 scanning\u2026")
                                   : qsTr("Align the QR code inside the frame")

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

    // Scan frame size: 300px on phones as in the design, larger on tablets,
    // shrinking on short windows so the hint, both buttons and the privacy
    // pill below it always fit without scrolling.
    readonly property real frameSize: {
        var widthCap = Math.min(page.width - 48, page.wideLayout ? 420 : 300)
        var heightCap = page.height - 300
        return Math.max(160, Math.min(widthCap, heightCap))
    }

    function startCamera() {
        if (mediaDevices.videoInputs.length === 0) {
            page.cameraRequested = false
            page.errorMessage = qsTr("No camera was found")
            return
        }
        page.cameraRequested = true
        page.errorMessage = ""
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
        page.errorMessage = ""
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

    // Activates the camera after an explicit tap on "Turn on camera" (or on
    // the frame). Permission is requested on first use.
    function activate() {
        if (mediaDevices.videoInputs.length === 0) {
            page.errorMessage = qsTr("No camera was found")
            return
        }
        if (cameraPermission.status === Qt.PermissionStatus.Granted)
            page.startCamera()
        else if (cameraPermission.status === Qt.PermissionStatus.Denied) {
            page.errorMessage = qsTr("Camera permission was denied")
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
                page.errorMessage = qsTr("Camera permission was denied")
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
            page.errorMessage = errorString
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
            const excludedWifi = appSettings.historyExcludeWifiPassword
                                 && text.startsWith("WIFI:")
            if (appSettings.historyEnabled && !excludedWifi)
                scanHistory.addEntry(text, page.classifyType(text))
        }

        function onDecodeFailed(reason) {
            page.imageDecoding = false
            page.errorMessage = reason
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


    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: page.wideLayout ? 24 : 32
        anchors.bottomMargin: 20
        spacing: 20

        // Centres the content vertically on tablets/desktop; phones keep the
        // design's top-aligned flow.
        Item { Layout.fillHeight: true; visible: page.wideLayout }

        // Scan frame. The live camera runs inside it; when off it shows a
        // "Camera is off" placeholder.
        Item {
            id: frame
            readonly property real cornerRadius: 28
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: page.frameSize
            Layout.preferredHeight: page.frameSize

            Rectangle {
                anchors.fill: parent
                radius: frame.cornerRadius
                color: page.cameraRequested ? "#1E2731"
                                            : (page.Material.theme === Material.Dark ? page.surfaceColor : "#E6EEEB")
            }

            VideoOutput {
                id: cameraOutput
                anchors.fill: parent
                visible: page.cameraRequested
                fillMode: VideoOutput.PreserveAspectCrop
            }

            // Sweep line while scanning.
            Rectangle {
                width: parent.width
                height: 2
                visible: page.cameraRequested && camera.active
                color: "#3CCFB4"
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: page.cameraRequested && camera.active
                    NumberAnimation { from: 6; to: frame.height - 8; duration: 1700; easing.type: Easing.InOutSine }
                    NumberAnimation { from: frame.height - 8; to: 6; duration: 1700; easing.type: Easing.InOutSine }
                }
            }

            // Rounds the video's square corners: a canvas-coloured ring whose
            // inner edge has the frame's corner radius (no shader needed).
            Rectangle {
                readonly property real ring: 24
                anchors.centerIn: parent
                width: parent.width + 2 * ring
                height: parent.height + 2 * ring
                radius: frame.cornerRadius + ring
                color: "transparent"
                border.width: ring
                border.color: page.canvasColor
            }

            ColumnLayout {
                anchors.centerIn: parent
                visible: !page.cameraRequested
                spacing: 12

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: 32
                    color: page.containerColor
                    SvgIcon {
                        anchors.centerIn: parent
                        source: "qrc:/icons/video.svg"
                        color: page.primaryColor
                        size: 26
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Camera is off")
                    color: page.mutedColor
                    font.pixelSize: 14
                }
            }

            // Corner brackets: each is a 48px window onto the corner of a
            // full-size rounded outline.
            Repeater {
                model: 4
                delegate: Item {
                    required property int index
                    readonly property bool atRight: index % 2 === 1
                    readonly property bool atBottom: index >= 2
                    x: atRight ? frame.width - width : 0
                    y: atBottom ? frame.height - height : 0
                    width: 48
                    height: 48
                    clip: true
                    Rectangle {
                        x: parent.atRight ? parent.width - frame.width : 0
                        y: parent.atBottom ? parent.height - frame.height : 0
                        width: frame.width
                        height: frame.height
                        radius: frame.cornerRadius
                        color: "transparent"
                        border.width: 5
                        border.color: page.primaryColor
                    }
                }
            }

            TapHandler {
                enabled: !page.cameraRequested && !page.imageDecoding
                onTapped: page.activate()
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: page.imageDecoding
                visible: running
            }

            // Flashlight toggle; only offered when the camera reports torch support.
            RoundButton {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                width: 48
                height: 48
                padding: 0
                flat: true
                visible: camera.active && camera.isTorchModeSupported(Camera.TorchOn)
                Accessible.name: page.torchOn ? qsTr("Turn off flashlight") : qsTr("Turn on flashlight")
                onClicked: {
                    page.torchOn = !page.torchOn
                    camera.torchMode = page.torchOn ? Camera.TorchOn : Camera.TorchOff
                }
                background: Rectangle {
                    radius: width / 2
                    color: page.torchOn ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(0, 0, 0, 0.45)
                }
                contentItem: Item {
                    SvgIcon {
                        anchors.centerIn: parent
                        source: "qrc:/icons/flash.svg"
                        color: page.torchOn ? "#161616" : "#FFFFFF"
                        size: 22
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: page.hint
            color: page.errorMessage.length > 0 ? page.errorColor : Material.foreground
            font.pixelSize: 16
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: page.frameSize
            Layout.maximumWidth: page.frameSize
            spacing: 10

            Button {
                id: cameraButton
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                topInset: 0
                bottomInset: 0
                enabled: !page.imageDecoding
                Accessible.name: text
                text: page.cameraRequested ? qsTr("Turn off camera") : qsTr("Turn on camera")
                onClicked: page.cameraRequested ? page.stopCamera() : page.activate()
                background: Rectangle {
                    radius: height / 2
                    color: page.primaryColor
                    opacity: cameraButton.enabled ? (cameraButton.down ? 0.85 : 1) : 0.5
                }
                contentItem: RowLayout {
                    spacing: 10
                    Item { Layout.fillWidth: true }
                    SvgIcon {
                        source: "qrc:/icons/video.svg"
                        color: page.primaryTextColor
                        size: 20
                    }
                    Label {
                        text: cameraButton.text
                        color: page.primaryTextColor
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            Button {
                id: imageButton
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                topInset: 0
                bottomInset: 0
                enabled: !page.imageDecoding
                Accessible.name: text
                text: qsTr("Choose image")
                onClicked: page.chooseImage()
                background: Rectangle {
                    radius: height / 2
                    color: imageButton.down ? page.containerColor : page.surfaceColor
                    border.width: 1
                    border.color: "#8A9693"
                    opacity: imageButton.enabled ? 1 : 0.5
                }
                contentItem: RowLayout {
                    spacing: 10
                    Item { Layout.fillWidth: true }
                    SvgIcon {
                        source: "qrc:/icons/image.svg"
                        color: page.primaryColor
                        size: 20
                    }
                    Label {
                        text: imageButton.text
                        color: page.primaryColor
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Privacy pill.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            implicitWidth: privacyRow.implicitWidth + 32
            implicitHeight: 36
            radius: 18
            color: page.containerColor

            RowLayout {
                id: privacyRow
                anchors.centerIn: parent
                spacing: 8
                SvgIcon {
                    source: "qrc:/icons/shield.svg"
                    color: page.containerTextColor
                    size: 16
                }
                Label {
                    text: qsTr("Decoded on this device · no tracking")
                    color: page.containerTextColor
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
