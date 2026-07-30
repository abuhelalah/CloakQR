import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: page
    title: qsTr("Settings")
    property bool wideLayout: false
    property color canvasColor: "#F3F7F5"
    property color primaryColor: "#086C5C"
    property color mutedColor: "#5D6F69"

    background: Rectangle {
        color: page.canvasColor
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(page.width, page.wideLayout ? 760 : 600)
            x: Math.max(0, (page.width - width) / 2)
            spacing: 10

            Label {
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.topMargin: page.wideLayout ? 28 : 20
                text: qsTr("Settings")
                font.pixelSize: page.wideLayout ? 28 : 23
                font.bold: true
            }

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                text: qsTr("Privacy, appearance and accessibility")
                color: page.mutedColor
                wrapMode: Text.WordWrap
                Layout.bottomMargin: 8
            }

            // --- Appearance ---------------------------------------------------
            Label {
                Layout.leftMargin: page.wideLayout ? 28 : 20
                text: qsTr("Appearance")
                font.bold: true
                color: page.primaryColor
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                spacing: 12

                Label {
                    text: qsTr("Theme")
                    Layout.fillWidth: true
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

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                spacing: 12

                Label {
                    text: qsTr("High contrast")
                    Layout.fillWidth: true
                }

                Switch {
                    Accessible.name: qsTr("High contrast toggle")
                    checked: appSettings.highContrast
                    onToggled: appSettings.highContrast = checked
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: qsTr("Text size")
                        Layout.fillWidth: true
                    }
                    Label {
                        text: Math.round(appSettings.fontScale * 100) + "%"
                        opacity: 0.7
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

            MenuSeparator { Layout.fillWidth: true }

            // --- Language -----------------------------------------------------
            Label {
                Layout.leftMargin: page.wideLayout ? 28 : 20
                text: qsTr("Language")
                font.bold: true
                color: page.primaryColor
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                spacing: 12

                Label {
                    text: qsTr("App language")
                    Layout.fillWidth: true
                }

                ComboBox {
                    id: languageBox
                    Accessible.name: qsTr("Language selector")
                    textRole: "label"
                    valueRole: "value"
                    model: [
                        { label: qsTr("System"),   value: "system" },
                        { label: qsTr("English"),  value: "en" },
                        { label: qsTr("Español"),  value: "es" },
                        { label: qsTr("Français"), value: "fr" },
                        { label: qsTr("العربية"),   value: "ar" }
                    ]
                    Component.onCompleted: currentIndex = indexOfValue(appSettings.language)
                    onModelChanged: currentIndex = indexOfValue(appSettings.language)
                    onActivated: appSettings.language = currentValue
                }
            }

            MenuSeparator { Layout.fillWidth: true }

            // --- Privacy ------------------------------------------------------
            Label {
                Layout.leftMargin: page.wideLayout ? 28 : 20
                text: qsTr("Privacy")
                font.bold: true
                color: page.primaryColor
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { text: qsTr("Save scan history") }
                    Label {
                        text: qsTr("Store scanned codes on this device")
                        font.pixelSize: 11
                        opacity: 0.6
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Switch {
                    Accessible.name: qsTr("Save scan history toggle")
                    checked: appSettings.historyEnabled
                    onToggled: appSettings.historyEnabled = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { text: qsTr("Exclude Wi-Fi passwords") }
                    Label {
                        text: qsTr("Never store Wi-Fi passwords in history")
                        font.pixelSize: 11
                        opacity: 0.6
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Switch {
                    Accessible.name: qsTr("Exclude Wi-Fi passwords toggle")
                    checked: appSettings.historyExcludeWifiPassword
                    onToggled: appSettings.historyExcludeWifiPassword = checked
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                text: qsTr("Clear scan history")
                enabled: scanHistory !== null && scanHistory.count > 0
                Accessible.name: qsTr("Clear scan history")
                onClicked: scanHistory.clear()
            }

            MenuSeparator { Layout.fillWidth: true }

            Button {
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.bottomMargin: 16
                flat: true
                text: qsTr("Reset all settings")
                Accessible.name: qsTr("Reset all settings")
                onClicked: {
                    appSettings.resetToDefaults()
                    themeBox.currentIndex = themeBox.indexOfValue(appSettings.theme)
                    languageBox.currentIndex = languageBox.indexOfValue(appSettings.language)
                }
            }
        }
    }
}
