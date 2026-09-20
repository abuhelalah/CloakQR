import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtMultimedia

Page {
    id: page
    title: qsTr("Settings")
    property bool wideLayout: false
    property color canvasColor: "#F3F7F5"
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#086C5C"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#5D6F69"

    // Emitted when the user taps "About CloakQR"; the host navigates to About.
    signal openAbout()

    // Settings reads scanHistory.count for its storage status, so trigger the
    // deferred history load the first time this page is shown.
    Component.onCompleted: if (visible) scanHistory.ensureLoaded()
    onVisibleChanged: if (visible) scanHistory.ensureLoaded()

    // Destructive-action colour and card divider tint.
    readonly property color dangerColor: "#D32F2F"
    readonly property color dividerColor: Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.16)

    // Summaries for the system-status card.
    function cameraStatusText() {
        if (mediaDevices.videoInputs.length === 0)
            return qsTr("No camera")
        switch (cameraPermission.status) {
        case Qt.PermissionStatus.Granted: return qsTr("Granted")
        case Qt.PermissionStatus.Denied:  return qsTr("Denied")
        default:                          return qsTr("Not requested")
        }
    }

    function storageStatusText() {
        const n = scanHistory !== null ? scanHistory.count : 0
        if (n <= 0) return qsTr("Nothing stored")
        return n === 1 ? qsTr("1 code") : qsTr("%1 codes").arg(n)
    }

    background: Rectangle {
        color: page.canvasColor
    }

    MediaDevices { id: mediaDevices }
    CameraPermission { id: cameraPermission }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(page.width, page.wideLayout ? 760 : 600)
            x: Math.max(0, (page.width - width) / 2)
            spacing: 8

            // Privacy promise.
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: page.wideLayout ? 28 : 20
                Layout.bottomMargin: 4
                radius: 14
                color: page.primaryColor
                implicitHeight: promiseRow.implicitHeight + 28

                RowLayout {
                    id: promiseRow
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    SvgIcon {
                        source: "qrc:/icons/shield.svg"
                        color: page.primaryTextColor
                        size: 28
                        Layout.alignment: Qt.AlignVCenter
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Private by design")
                            font.bold: true
                            font.pixelSize: 16
                            color: page.primaryTextColor
                        }
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("No ads, no tracking, no cloud. Scanning happens entirely on this device.")
                            color: Qt.rgba(page.primaryTextColor.r, page.primaryTextColor.g,
                                           page.primaryTextColor.b, 0.88)
                            wrapMode: Text.WordWrap
                            font.pixelSize: 13
                        }
                    }
                }
            }

            // ===== SYSTEM STATUS =====
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: 10
                text: qsTr("System status")
                font.pixelSize: 11
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
                color: page.mutedColor
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                radius: 12
                color: page.surfaceColor
                implicitHeight: systemColumn.implicitHeight

                ColumnLayout {
                    id: systemColumn
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 12
                        SvgIcon {
                            source: "qrc:/icons/video.svg"
                            color: page.primaryColor
                            size: 18
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Camera")
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            text: page.cameraStatusText()
                            color: page.mutedColor
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 12
                        SvgIcon {
                            source: "qrc:/icons/folder.svg"
                            color: page.primaryColor
                            size: 18
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Storage")
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            text: page.storageStatusText()
                            color: page.mutedColor
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // ===== PRIVACY & SECURITY =====
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: 10
                text: qsTr("Privacy & security")
                font.pixelSize: 11
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
                color: page.mutedColor
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                radius: 12
                color: page.surfaceColor
                implicitHeight: privacyColumn.implicitHeight

                ColumnLayout {
                    id: privacyColumn
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Save scan history")
                                wrapMode: Text.WordWrap
                            }
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Store scanned codes on this device")
                                font.pixelSize: 11
                                color: page.mutedColor
                                wrapMode: Text.WordWrap
                            }
                        }
                        Switch {
                            Accessible.name: qsTr("Save scan history toggle")
                            checked: appSettings.historyEnabled
                            onToggled: appSettings.historyEnabled = checked
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Exclude Wi-Fi passwords")
                                wrapMode: Text.WordWrap
                            }
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Never store Wi-Fi passwords in history")
                                font.pixelSize: 11
                                color: page.mutedColor
                                wrapMode: Text.WordWrap
                            }
                        }
                        Switch {
                            Accessible.name: qsTr("Exclude Wi-Fi passwords toggle")
                            checked: appSettings.historyExcludeWifiPassword
                            onToggled: appSettings.historyExcludeWifiPassword = checked
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Biometric lock")
                                wrapMode: Text.WordWrap
                            }
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Require fingerprint or face to open the app")
                                font.pixelSize: 11
                                color: page.mutedColor
                                wrapMode: Text.WordWrap
                            }
                        }
                        Switch {
                            Accessible.name: qsTr("Biometric lock toggle")
                            checked: appSettings.biometricLockEnabled
                            onToggled: {
                                if (checked && Qt.platform.os === "android"
                                        && !platformBridge.isBiometricAvailable()) {
                                    appSettings.biometricLockEnabled = false
                                    biometricUnavailable.open()
                                    return
                                }
                                appSettings.biometricLockEnabled = checked
                            }
                        }
                    }
                }
            }

            // ===== APP SETTINGS =====
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: 10
                text: qsTr("App settings")
                font.pixelSize: 11
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
                color: page.mutedColor
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                radius: 12
                color: page.surfaceColor
                implicitHeight: appColumn.implicitHeight

                ColumnLayout {
                    id: appColumn
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 12
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Theme")
                            verticalAlignment: Text.AlignVCenter
                        }
                        ComboBox {
                            id: themeBox
                            Accessible.name: qsTr("Theme selector")
                            textRole: "label"
                            valueRole: "value"
                            model: [
                                { label: qsTr("System"), value: "system" },
                                { label: qsTr("Light"),  value: "light" },
                                { label: qsTr("Dark"),   value: "dark" }
                            ]
                            Component.onCompleted: currentIndex = indexOfValue(appSettings.theme)
                            onModelChanged: currentIndex = indexOfValue(appSettings.theme)
                            onActivated: appSettings.theme = currentValue
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 12
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("App language")
                            verticalAlignment: Text.AlignVCenter
                        }
                        ComboBox {
                            id: languageBox
                            Accessible.name: qsTr("Language selector")
                            textRole: "label"
                            valueRole: "value"
                            model: [
                                { label: qsTr("System"),   value: "system" },
                                { label: qsTr("English"),  value: "en" },
                                { label: qsTr("العربية"),   value: "ar" },
                                { label: qsTr("Español"),  value: "es" },
                                { label: qsTr("Français"), value: "fr" }
                            ]
                            Component.onCompleted: currentIndex = indexOfValue(appSettings.language)
                            onModelChanged: currentIndex = indexOfValue(appSettings.language)
                            onActivated: appSettings.language = currentValue
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 12
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("High contrast")
                            verticalAlignment: Text.AlignVCenter
                        }
                        Switch {
                            Accessible.name: qsTr("High contrast toggle")
                            checked: appSettings.highContrast
                            onToggled: appSettings.highContrast = checked
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: 12
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Text size")
                            }
                            Label {
                                text: Math.round(appSettings.fontScale * 100) + "%"
                                color: page.mutedColor
                            }
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 0.8
                            to: 2.0
                            stepSize: 0.1
                            value: appSettings.fontScale
                            Accessible.name: qsTr("Text size slider")
                            onMoved: appSettings.fontScale = value
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    Button {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        flat: true
                        Accessible.name: qsTr("About CloakQR")
                        onClicked: page.openAbout()

                        contentItem: RowLayout {
                            spacing: 10
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("About CloakQR")
                                verticalAlignment: Text.AlignVCenter
                            }
                            SvgIcon {
                                source: "qrc:/icons/chevron_right.svg"
                                color: page.mutedColor
                                size: 16
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }

            // ===== DANGER ZONE =====
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: 10
                text: qsTr("Danger zone")
                font.pixelSize: 11
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
                color: page.dangerColor
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                radius: 12
                color: page.surfaceColor
                border.width: 1
                border.color: Qt.rgba(page.dangerColor.r, page.dangerColor.g, page.dangerColor.b, 0.35)
                implicitHeight: dangerColumn.implicitHeight

                ColumnLayout {
                    id: dangerColumn
                    anchors.fill: parent
                    spacing: 0

                    Button {
                        id: clearHistoryBtn
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        flat: true
                        enabled: scanHistory !== null && scanHistory.count > 0
                        Accessible.name: qsTr("Clear scan history")
                        onClicked: clearConfirm.open()

                        contentItem: Label {
                            text: qsTr("Clear scan history")
                            color: clearHistoryBtn.enabled ? page.dangerColor : page.mutedColor
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        Layout.preferredHeight: 1
                        color: page.dividerColor
                    }

                    Button {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        flat: true
                        Accessible.name: qsTr("Reset all settings")
                        onClicked: {
                            appSettings.resetToDefaults()
                            themeBox.currentIndex = themeBox.indexOfValue(appSettings.theme)
                            languageBox.currentIndex = languageBox.indexOfValue(appSettings.language)
                        }

                        contentItem: Label {
                            text: qsTr("Reset all settings")
                            color: page.dangerColor
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // ===== Version footer =====
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 24
                text: (appEngine.paidEdition ? qsTr("CloakQR Pro") : qsTr("CloakQR")) + " \u00B7 " + qsTr("v%1").arg(appEngine.version)
                color: page.mutedColor
                font.pixelSize: 12
            }
        }
    }

    ConfirmDialog {
        id: clearConfirm
        message: qsTr("Delete all saved scans? This cannot be undone.")
        confirmText: qsTr("Delete all")
        onConfirmed: scanHistory.clear()
    }

    Popup {
        id: biometricUnavailable
        modal: true
        anchors.centerIn: parent
        width: Math.min(360, page.width - 48)
        padding: 20
        background: Rectangle {
            color: page.surfaceColor
            radius: 14
        }

        ColumnLayout {
            width: parent.width
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: qsTr("Biometric lock unavailable")
                font.bold: true
                font.pixelSize: 15
            }
            Label {
                Layout.fillWidth: true
                text: qsTr("This device has no enrolled fingerprint or face. Set up biometrics in your system settings to use this feature.")
                color: page.mutedColor
                wrapMode: Text.WordWrap
                font.pixelSize: 13
            }
            Button {
                Layout.alignment: Qt.AlignRight
                text: qsTr("OK")
                onClicked: biometricUnavailable.close()
            }
        }
    }
}
