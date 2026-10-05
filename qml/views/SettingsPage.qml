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
    property color canvasColor: "#F1F5F3"
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#0B6B5E"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#4B5754"
    property color containerColor: "#D5EBE4"
    property color containerTextColor: "#053B33"

    // Emitted when the user taps "About CloakQR"; the host navigates to About.
    signal openAbout()

    // Settings reads scanHistory.count for its storage status, so trigger the
    // deferred history load the first time this page is shown.
    Component.onCompleted: if (visible) scanHistory.ensureLoaded()
    onVisibleChanged: if (visible) scanHistory.ensureLoaded()

    // Destructive-action colour (theme-aware, from main.qml) and card divider tint.
    property color errorColor: "#B3261E"
    readonly property color dangerColor: errorColor
    readonly property color dividerColor: Material.theme === Material.Dark ? Qt.rgba(1, 1, 1, 0.12) : "#E3E8E6"
    readonly property real sideMargin: page.wideLayout ? 28 : 16
    // The rail layout has no top bar, so the page shows its own title there.
    readonly property bool showTitle: ApplicationWindow.window !== null
                                      && ApplicationWindow.window.railLayout === true
    // The promise card is solid primary in light mode; in dark mode a tonal
    // fill keeps the large block from glaring.
    readonly property bool dark: Material.theme === Material.Dark
    readonly property color promiseColor: dark ? containerColor : primaryColor
    readonly property color promiseTextColor: dark ? containerTextColor : primaryTextColor

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

    background: Rectangle {
        color: page.canvasColor
    }

    MediaDevices { id: mediaDevices }
    CameraPermission { id: cameraPermission }

    // --- Building blocks -----------------------------------------------------
    component SectionHeader: Label {
        Layout.fillWidth: true
        Layout.leftMargin: page.sideMargin + 4
        Layout.rightMargin: page.sideMargin + 4
        Layout.topMargin: 16
        Layout.bottomMargin: 4
        font.pixelSize: 12
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
        color: page.mutedColor
    }

    component Card: Rectangle {
        default property alias content: cardColumn.data
        Layout.fillWidth: true
        Layout.leftMargin: page.sideMargin
        Layout.rightMargin: page.sideMargin
        radius: 20
        color: page.surfaceColor
        implicitHeight: cardColumn.implicitHeight
        ColumnLayout {
            id: cardColumn
            anchors.fill: parent
            spacing: 0
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.preferredHeight: 1
        color: page.dividerColor
    }

    // Title + optional subtitle on the left, a Switch on the right.
    component SwitchRow: RowLayout {
        id: switchRow
        property string title
        property string subtitle
        property bool checked
        signal toggled(bool checked)
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 8
        Layout.topMargin: 10
        Layout.bottomMargin: 10
        spacing: 12
        opacity: enabled ? 1 : 0.5
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label {
                Layout.fillWidth: true
                text: switchRow.title
                font.pixelSize: 16
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                visible: text.length > 0
                text: switchRow.subtitle
                font.pixelSize: 13
                color: page.mutedColor
                wrapMode: Text.WordWrap
            }
        }
        Switch {
            Accessible.name: switchRow.title
            checked: switchRow.checked
            onToggled: {
                switchRow.toggled(checked)
                // Snap back to the stored value if the handler refused it.
                checked = Qt.binding(() => switchRow.checked)
            }
        }
    }

    // Icon, label and a trailing value, as in the Status card.
    component StatusRow: RowLayout {
        property alias icon: statusIcon.source
        property alias label: statusLabel.text
        property alias value: statusValue.text
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.topMargin: 14
        Layout.bottomMargin: 14
        spacing: 14
        SvgIcon {
            id: statusIcon
            color: page.primaryColor
            size: 22
        }
        Label {
            id: statusLabel
            Layout.fillWidth: true
            font.pixelSize: 16
        }
        Label {
            id: statusValue
            font.pixelSize: 14
            color: page.mutedColor
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(page.width, page.wideLayout ? 760 : 600)
            x: Math.max(0, (page.width - width) / 2)
            spacing: 8

            // Tablet/desktop has no top bar, so the page carries its own title.
            Label {
                visible: page.showTitle
                Layout.leftMargin: page.sideMargin
                Layout.topMargin: 28
                text: qsTr("Settings")
                font.pixelSize: Math.round(28 * appSettings.fontScale)
                font.bold: true
            }

            // Privacy promise.
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: page.sideMargin
                Layout.rightMargin: page.sideMargin
                Layout.topMargin: page.wideLayout ? 6 : 16
                radius: 20
                color: page.promiseColor
                implicitHeight: promiseRow.implicitHeight + 36

                RowLayout {
                    id: promiseRow
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    SvgIcon {
                        Layout.alignment: Qt.AlignTop
                        source: "qrc:/icons/shield.svg"
                        color: page.promiseTextColor
                        size: 26
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Private by design")
                            font.bold: true
                            font.pixelSize: 17
                            color: page.promiseTextColor
                        }
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("No ads, no tracking, no cloud. Everything happens on this device.")
                            color: Qt.rgba(page.promiseTextColor.r, page.promiseTextColor.g,
                                           page.promiseTextColor.b, 0.88)
                            wrapMode: Text.WordWrap
                            font.pixelSize: 14
                            lineHeight: 1.2
                        }
                    }
                }
            }

            SectionHeader { text: qsTr("Privacy & security") }
            Card {
                SwitchRow {
                    title: qsTr("Save history")
                    subtitle: qsTr("Last %1 codes, on this device").arg(scanHistory.maxEntries)
                    checked: appSettings.historyEnabled
                    onToggled: (on) => appSettings.historyEnabled = on
                }
                Divider {}
                SwitchRow {
                    // Only meaningful while history is being saved.
                    enabled: appSettings.historyEnabled
                    title: qsTr("Exclude Wi-Fi passwords")
                    subtitle: qsTr("Never store them in history")
                    checked: appSettings.historyExcludeWifiPassword
                    onToggled: (on) => appSettings.historyExcludeWifiPassword = on
                }
                Divider {}
                SwitchRow {
                    title: qsTr("Biometric lock")
                    subtitle: qsTr("Fingerprint or face to open")
                    checked: appSettings.biometricLockEnabled
                    onToggled: (on) => {
                        if (on && Qt.platform.os === "android"
                                && !platformBridge.isBiometricAvailable()) {
                            appSettings.biometricLockEnabled = false
                            biometricUnavailable.open()
                            return
                        }
                        appSettings.biometricLockEnabled = on
                    }
                }
            }

            SectionHeader { text: qsTr("Appearance") }
            Card {
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: 16
                    Layout.topMargin: 14
                    spacing: 10
                    Label {
                        text: qsTr("Theme")
                        font.pixelSize: 16
                    }
                    SegmentedControl {
                        Layout.fillWidth: true
                        model: [
                            { key: "system", label: qsTr("System") },
                            { key: "light",  label: qsTr("Light") },
                            { key: "dark",   label: qsTr("Dark") }
                        ]
                        currentKey: appSettings.theme
                        fillColor: page.surfaceColor
                        selectedColor: page.containerColor
                        selectedTextColor: page.containerTextColor
                        textColor: page.mutedColor
                        Accessible.name: qsTr("Theme selector")
                        onActivated: (key) => appSettings.theme = key
                    }
                }
                Divider {}
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.topMargin: 6
                    Layout.bottomMargin: 6
                    spacing: 12
                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Language")
                        font.pixelSize: 16
                    }
                    ComboBox {
                        id: languageBox
                        Layout.preferredWidth: 160
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
                Divider {}
                SwitchRow {
                    title: qsTr("High contrast")
                    checked: appSettings.highContrast
                    onToggled: (on) => appSettings.highContrast = on
                }
                Divider {}
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    Layout.topMargin: 12
                    Layout.bottomMargin: 8
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("Text size")
                            font.pixelSize: 16
                        }
                        Label {
                            text: Math.round(appSettings.fontScale * 100) + "%"
                            color: page.primaryColor
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
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
            }

            SectionHeader { text: qsTr("Status") }
            Card {
                StatusRow {
                    icon: "qrc:/icons/video.svg"
                    label: qsTr("Camera")
                    value: page.cameraStatusText()
                }
                Divider {}
                StatusRow {
                    icon: "qrc:/icons/nav_history.svg"
                    label: qsTr("Saved codes")
                    value: scanHistory.count
                }
                Divider {}
                ItemDelegate {
                    Layout.fillWidth: true
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 14
                    bottomPadding: 14
                    Accessible.name: qsTr("About CloakQR")
                    onClicked: page.openAbout()
                    background: Item {}
                    contentItem: RowLayout {
                        spacing: 14
                        SvgIcon {
                            source: "qrc:/icons/info.svg"
                            color: page.primaryColor
                            size: 22
                        }
                        Label {
                            Layout.fillWidth: true
                            text: qsTr("About CloakQR")
                            font.pixelSize: 16
                        }
                        SvgIcon {
                            source: Qt.application.layoutDirection === Qt.RightToLeft ? "qrc:/icons/chevron_left.svg"
                                                            : "qrc:/icons/chevron_right.svg"
                            color: page.mutedColor
                            size: 20
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Danger zone")
                color: page.dangerColor
            }
            Card {
                Button {
                    id: clearHistoryBtn
                    Layout.fillWidth: true
                    flat: true
                    leftPadding: 16
                    enabled: scanHistory !== null && scanHistory.count > 0
                    Accessible.name: qsTr("Clear scan history")
                    onClicked: clearConfirm.open()
                    contentItem: Label {
                        text: qsTr("Clear scan history")
                        font.pixelSize: 16
                        color: clearHistoryBtn.enabled ? page.dangerColor : page.mutedColor
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Divider {}
                Button {
                    Layout.fillWidth: true
                    flat: true
                    leftPadding: 16
                    Accessible.name: qsTr("Reset all settings")
                    onClicked: {
                        appSettings.resetToDefaults()
                        languageBox.currentIndex = languageBox.indexOfValue(appSettings.language)
                    }
                    contentItem: Label {
                        text: qsTr("Reset all settings")
                        font.pixelSize: 16
                        color: page.dangerColor
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 28
                text: (appEngine.paidEdition ? qsTr("CloakQR Pro") : qsTr("CloakQR")) + " · " + qsTr("v%1").arg(appEngine.version)
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
            radius: 20
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
