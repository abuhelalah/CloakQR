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
    readonly property bool useNativePicker: Qt.platform.os === "android"
                                            || Qt.platform.os === "ios"

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
            if (appSettings.historyEnabled && !excludedWifi) {
                const type = /^https?:\/\//i.test(text) ? "url" : "text"
                scanHistory.addEntry(text, type)
            }
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
