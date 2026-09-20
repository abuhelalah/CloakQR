import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    width: 420
    height: 860
    minimumWidth: 360
    minimumHeight: 640
    visible: true
    // Phones/tablets on Android and iOS are managed fullscreen by the platform;
    // on desktop the window opens maximised so tablets and desktops use the full
    // screen instead of a phone-sized window.
    visibility: (Qt.platform.os === "android" || Qt.platform.os === "ios")
                ? Window.AutomaticVisibility
                : Window.Maximized
    title: appEngine.paidEdition ? qsTr("CloakQR Pro") : qsTr("CloakQR")

    readonly property bool compactLayout: width < 600
    readonly property bool railLayout: width >= 840
    readonly property bool darkTheme: appSettings.darkMode

    // Material 2 dark-theme palette: a dark-grey (#121212) background expresses
    // space, surfaces grow lighter at higher elevation to convey depth, and the
    // brand teal is desaturated so it clears WCAG AA (4.5:1) on every surface.
    // Large areas stay dark; saturated colour is reserved for small accents.
    readonly property color canvasColor: darkTheme ? "#121212" : "#F3F7F5"
    readonly property color surfaceColor: darkTheme ? "#1D2321" : "#FFFFFF"
    readonly property color elevatedSurfaceColor: darkTheme ? "#262D2B" : "#FFFFFF"
    readonly property color primaryColor: appSettings.highContrast
                                          ? (darkTheme ? "#80FFE9" : "#003D33")
                                          : (darkTheme ? "#5FD7C0" : "#086C5C")
    // Readable text/icon colour for content placed on top of primaryColor.
    // In dark mode the primary is a light teal, so "on-primary" is near-black;
    // in light mode the primary is dark teal, so "on-primary" is white.
    readonly property color primaryTextColor: darkTheme ? "#08211C" : "#FFFFFF"
    readonly property color mutedColor: darkTheme ? "#A6B3AF" : "#5D6F69"
    readonly property color accentColor: darkTheme ? "#FFB59A" : "#C84F2D"
    readonly property color outlineColor: darkTheme ? Qt.rgba(1, 1, 1, 0.12)
                                                    : Qt.rgba(0, 0, 0, 0.10)
    readonly property color errorColor: darkTheme ? "#CF6679" : "#B00020"
    property int currentPage: 0
    property int previousTab: 0
    // Lazily-loaded pages: each becomes true on first navigation so its Loader
    // activates (and stays active, preserving state between visits).
    property bool generatorVisited: false
    property bool historyVisited: false
    property bool settingsVisited: false
    property bool aboutVisited: false
    // Settings, About and the paid tools are "pushed" sub-pages: they get a
    // back button and hide the bottom navigation bar.
    readonly property bool subPage: currentPage > 2

    readonly property var navModel: {
        var items = [
            { page: 0, label: qsTr("Scan"), title: qsTr("Scan QR"), a11y: qsTr("Scanner"), group: 0, icon: "qrc:/icons/nav_scan.svg" },
            { page: 1, label: qsTr("Create QR"), a11y: qsTr("Create QR code"), group: 0, icon: "qrc:/icons/create.svg" }
        ]
        if (appEngine.paidEdition) {
            items.push({ page: 4, label: qsTr("Design Studio"), a11y: qsTr("Design Studio"), group: 1 })
            items.push({ page: 5, label: qsTr("Batch Studio"), a11y: qsTr("Batch Studio"), group: 1 })
        }
        items.push({ page: 2, label: qsTr("History"), a11y: qsTr("History"), group: 2, icon: "qrc:/icons/nav_history.svg" })
        items.push({ page: 3, label: qsTr("Settings"), a11y: qsTr("Settings"), group: 2 })
        items.push({ page: 6, label: qsTr("About"), a11y: qsTr("About"), group: 3 })
        return items
    }

    // Primary tabs shown in the compact bottom navigation bar.
    readonly property var bottomNavModel: [
        { page: 0, label: qsTr("Scan"),    a11y: qsTr("Scanner"),        icon: "qrc:/icons/nav_scan.svg" },
        { page: 1, label: qsTr("Create"),  a11y: qsTr("Create QR code"), icon: "qrc:/icons/nav_create.svg" },
        { page: 2, label: qsTr("History"), a11y: qsTr("History"),        icon: "qrc:/icons/nav_history.svg" }
    ]

    Material.theme: appSettings.darkMode ? Material.Dark : Material.Light
    Material.primary: Material.Teal
    Material.accent: Material.Teal
    font.pixelSize: Math.round(14 * appSettings.fontScale)
    color: canvasColor

    // Mirror the whole UI for right-to-left locales (e.g. Arabic).
    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    function currentTitle() {
        for (var i = 0; i < navModel.length; ++i)
            if (navModel[i].page === currentPage)
                return navModel[i].title || navModel[i].label
        return ""
    }

    function currentIcon() {
        for (var i = 0; i < navModel.length; ++i)
            if (navModel[i].page === currentPage)
                return navModel[i].icon || ""
        return ""
    }

    function navigateTo(index) {
        if (index >= 0 && index < pageStack.count) {
            if (index <= 2)
                root.previousTab = index
            root.currentPage = index
            if (index === 1)
                root.generatorVisited = true
            else if (index === 2)
                root.historyVisited = true
            else if (index === 3)
                root.settingsVisited = true
            else if (index === 6)
                root.aboutVisited = true
        }
    }

    // Gates the app behind biometrics on launch when the user opted in.
    // Android-only; silently skips when the feature is unavailable.
    function lockIfNeeded() {
        if (!appSettings.biometricLockEnabled)
            return
        if (Qt.platform.os !== "android")
            return
        if (!platformBridge.isBiometricAvailable())
            return
        lockOverlay.visible = true
        unlockButton.visible = false
        lockHint.text = qsTr("Confirm your identity to continue")
        authTriggerTimer.start()
    }

    SafePreviewDialog {
        id: scanResultDialog
        surfaceColor: root.elevatedSurfaceColor
        primaryColor: root.primaryColor
        primaryTextColor: root.primaryTextColor
        mutedColor: root.mutedColor
        accentColor: root.accentColor
    }

    Connections {
        target: qrDecoder

        function onDecodeSucceeded(text) {
            scanResultDialog.show(text)
        }
    }

    Connections {
        target: platformBridge

        function onBiometricAuthenticated(success) {
            authTriggerTimer.stop()
            if (success) {
                lockOverlay.visible = false
                unlockButton.visible = false
            } else {
                lockHint.text = qsTr("Authentication failed or cancelled")
                unlockButton.visible = true
            }
        }
    }

    // Gives the window/activity a moment to be fully resumed before the system
    // biometric prompt is presented on top of it.
    Timer {
        id: authTriggerTimer
        interval: 400
        repeat: false
        onTriggered: platformBridge.authenticate()
    }

    // Full-screen shield shown while the biometric prompt is pending (and after
    // a failed/cancelled attempt) so content stays hidden until unlocked.
    Rectangle {
        id: lockOverlay
        anchors.fill: parent
        visible: false
        z: 20
        color: root.canvasColor

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            SvgIcon {
                Layout.alignment: Qt.AlignHCenter
                source: "qrc:/icons/lock.svg"
                color: root.primaryColor
                size: 44
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Unlock CloakQR")
                font.bold: true
                font.pixelSize: 18
            }
            Label {
                id: lockHint
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Confirm your identity to continue")
                color: root.mutedColor
                font.pixelSize: 13
            }
            Button {
                id: unlockButton
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                visible: false
                text: qsTr("Try again")
                onClicked: platformBridge.authenticate()
            }
        }
    }

    Component.onCompleted: root.lockIfNeeded()

    RowLayout {
        anchors.fill: parent
        // On Android 15+ (targetSdk 35+) the app draws edge-to-edge, so the
        // system status bar and gesture navigation bar overlap the window. Keep
        // the content inside the safe area while the window background colour
        // still fills the whole screen behind the bars. On desktop (and on
        // Android < 15) the margins are zero, so this is a no-op there.
        anchors.topMargin: root.SafeArea.margins.top
        anchors.bottomMargin: root.SafeArea.margins.bottom
        anchors.leftMargin: root.SafeArea.margins.left
        anchors.rightMargin: root.SafeArea.margins.right
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 232
            visible: root.railLayout
            color: root.surfaceColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 6

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    spacing: 0
                    Label {
                        text: appEngine.paidEdition ? qsTr("CloakQR Pro") : qsTr("CloakQR")
                        font.bold: true
                        font.pixelSize: 18
                    }
                    Label {
                        text: qsTr("Private by design")
                        color: root.mutedColor
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: root.navModel
                    delegate: ColumnLayout {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 6

                        MenuSeparator {
                            Layout.fillWidth: true
                            visible: index > 0
                                && modelData.group !== root.navModel[index - 1].group
                        }
                        ItemDelegate {
                            Layout.fillWidth: true
                            text: modelData.title || modelData.label
                            highlighted: root.currentPage === modelData.page
                            focusPolicy: Qt.StrongFocus
                            Accessible.name: modelData.a11y
                            Accessible.role: Accessible.Button
                            onClicked: root.navigateTo(modelData.page)
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: qsTr("LOCAL ONLY")
                        color: root.primaryColor
                        font.bold: true
                        font.pixelSize: 10
                    }
                    Label {
                        text: qsTr("No tracking · v%1").arg(Qt.application.version)
                        color: root.mutedColor
                        font.pixelSize: 11
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                visible: !root.railLayout
                color: root.surfaceColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 10
                    spacing: 0

                    ToolButton {
                        id: backButton
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.subPage
                        focusPolicy: Qt.StrongFocus
                        Accessible.name: qsTr("Back")
                        Accessible.role: Accessible.Button
                        onClicked: root.navigateTo(root.previousTab)

                        contentItem: Item {
                            SvgIcon {
                                anchors.centerIn: parent
                                source: "qrc:/icons/chevron_left.svg"
                                color: root.primaryColor
                                size: 22
                            }
                        }
                    }

                    SvgIcon {
                        visible: !root.subPage
                        source: root.currentIcon()
                        color: root.primaryColor
                        size: 20
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.alignment: Qt.AlignVCenter
                        text: root.currentTitle()
                        font.bold: true
                        font.pixelSize: 18
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    ToolButton {
                        id: moreButton
                        visible: !root.subPage
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        Layout.alignment: Qt.AlignVCenter
                        focusPolicy: Qt.StrongFocus
                        Accessible.name: qsTr("Settings")
                        Accessible.role: Accessible.Button
                        onClicked: root.navigateTo(3)

                        contentItem: Item {
                            SvgIcon {
                                anchors.centerIn: parent
                                source: "qrc:/icons/settings.svg"
                                color: root.primaryColor
                                size: 20
                            }
                        }
                    }
                }
            }

            StackLayout {
                id: pageStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPage

                ScannerPage {
                    id: scannerPage
                    wideLayout: !root.compactLayout
                    canvasColor: root.canvasColor
                    surfaceColor: root.surfaceColor
                    primaryColor: root.primaryColor
                    primaryTextColor: root.primaryTextColor
                    mutedColor: root.mutedColor
                    accentColor: root.accentColor
                }
                Loader {
                    id: generatorLoader
                    active: root.generatorVisited
                    asynchronous: true
                    source: "views/GeneratorPage.qml"
                }
                Binding {
                    target: generatorLoader.item
                    property: "wideLayout"
                    value: !root.compactLayout
                    when: generatorLoader.status === Loader.Ready
                }
                Binding {
                    target: generatorLoader.item
                    property: "canvasColor"
                    value: root.canvasColor
                    when: generatorLoader.status === Loader.Ready
                }
                Binding {
                    target: generatorLoader.item
                    property: "primaryColor"
                    value: root.primaryColor
                    when: generatorLoader.status === Loader.Ready
                }
                Binding {
                    target: generatorLoader.item
                    property: "primaryTextColor"
                    value: root.primaryTextColor
                    when: generatorLoader.status === Loader.Ready
                }
                Binding {
                    target: generatorLoader.item
                    property: "mutedColor"
                    value: root.mutedColor
                    when: generatorLoader.status === Loader.Ready
                }
                Loader {
                    id: historyLoader
                    active: root.historyVisited
                    asynchronous: true
                    source: "views/HistoryPage.qml"
                }
                Binding {
                    target: historyLoader.item
                    property: "wideLayout"
                    value: !root.compactLayout
                    when: historyLoader.status === Loader.Ready
                }
                Binding {
                    target: historyLoader.item
                    property: "canvasColor"
                    value: root.canvasColor
                    when: historyLoader.status === Loader.Ready
                }
                Binding {
                    target: historyLoader.item
                    property: "surfaceColor"
                    value: root.surfaceColor
                    when: historyLoader.status === Loader.Ready
                }
                Binding {
                    target: historyLoader.item
                    property: "primaryColor"
                    value: root.primaryColor
                    when: historyLoader.status === Loader.Ready
                }
                Binding {
                    target: historyLoader.item
                    property: "mutedColor"
                    value: root.mutedColor
                    when: historyLoader.status === Loader.Ready
                }
                Connections {
                    target: historyLoader.item
                    function onItemActivated(content) {
                        scanResultDialog.show(content)
                    }
                }
                Loader {
                    id: settingsLoader
                    active: root.settingsVisited
                    asynchronous: true
                    source: "views/SettingsPage.qml"
                }
                Binding {
                    target: settingsLoader.item
                    property: "wideLayout"
                    value: !root.compactLayout
                    when: settingsLoader.status === Loader.Ready
                }
                Binding {
                    target: settingsLoader.item
                    property: "canvasColor"
                    value: root.canvasColor
                    when: settingsLoader.status === Loader.Ready
                }
                Binding {
                    target: settingsLoader.item
                    property: "surfaceColor"
                    value: root.surfaceColor
                    when: settingsLoader.status === Loader.Ready
                }
                Binding {
                    target: settingsLoader.item
                    property: "primaryColor"
                    value: root.primaryColor
                    when: settingsLoader.status === Loader.Ready
                }
                Binding {
                    target: settingsLoader.item
                    property: "primaryTextColor"
                    value: root.primaryTextColor
                    when: settingsLoader.status === Loader.Ready
                }
                Binding {
                    target: settingsLoader.item
                    property: "mutedColor"
                    value: root.mutedColor
                    when: settingsLoader.status === Loader.Ready
                }
                Connections {
                    target: settingsLoader.item
                    function onOpenAbout() {
                        root.navigateTo(6)
                    }
                }
                Loader {
                    id: paidStudioLoader
                    active: appEngine.paidEdition
                    source: active ? "views/DesignStudioPanel.qml" : ""
                }
                Binding {
                    target: paidStudioLoader.item
                    property: "wideLayout"
                    value: !root.compactLayout
                    when: paidStudioLoader.status === Loader.Ready
                }
                Binding {
                    target: paidStudioLoader.item
                    property: "canvasColor"
                    value: root.canvasColor
                    when: paidStudioLoader.status === Loader.Ready
                }
                Binding {
                    target: paidStudioLoader.item
                    property: "surfaceColor"
                    value: root.surfaceColor
                    when: paidStudioLoader.status === Loader.Ready
                }
                Binding {
                    target: paidStudioLoader.item
                    property: "primaryColor"
                    value: root.primaryColor
                    when: paidStudioLoader.status === Loader.Ready
                }
                Binding {
                    target: paidStudioLoader.item
                    property: "mutedColor"
                    value: root.mutedColor
                    when: paidStudioLoader.status === Loader.Ready
                }
                Loader {
                    id: paidBatchLoader
                    active: appEngine.paidEdition
                    source: active ? "views/BatchStudioPanel.qml" : ""
                }
                Binding {
                    target: paidBatchLoader.item
                    property: "wideLayout"
                    value: !root.compactLayout
                    when: paidBatchLoader.status === Loader.Ready
                }
                Binding {
                    target: paidBatchLoader.item
                    property: "canvasColor"
                    value: root.canvasColor
                    when: paidBatchLoader.status === Loader.Ready
                }
                Binding {
                    target: paidBatchLoader.item
                    property: "surfaceColor"
                    value: root.surfaceColor
                    when: paidBatchLoader.status === Loader.Ready
                }
                Binding {
                    target: paidBatchLoader.item
                    property: "primaryColor"
                    value: root.primaryColor
                    when: paidBatchLoader.status === Loader.Ready
                }
                Binding {
                    target: paidBatchLoader.item
                    property: "mutedColor"
                    value: root.mutedColor
                    when: paidBatchLoader.status === Loader.Ready
                }
                Loader {
                    id: aboutLoader
                    active: root.aboutVisited
                    asynchronous: true
                    source: "views/AboutPage.qml"
                }
                Binding {
                    target: aboutLoader.item
                    property: "wideLayout"
                    value: !root.compactLayout
                    when: aboutLoader.status === Loader.Ready
                }
                Binding {
                    target: aboutLoader.item
                    property: "canvasColor"
                    value: root.canvasColor
                    when: aboutLoader.status === Loader.Ready
                }
                Binding {
                    target: aboutLoader.item
                    property: "surfaceColor"
                    value: root.surfaceColor
                    when: aboutLoader.status === Loader.Ready
                }
                Binding {
                    target: aboutLoader.item
                    property: "primaryColor"
                    value: root.primaryColor
                    when: aboutLoader.status === Loader.Ready
                }
                Binding {
                    target: aboutLoader.item
                    property: "mutedColor"
                    value: root.mutedColor
                    when: aboutLoader.status === Loader.Ready
                }
            }

            // Compact bottom navigation bar (SCAN / CREATE / HISTORY).
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                visible: !root.railLayout && !root.subPage
                color: root.surfaceColor

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.outlineColor
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: root.bottomNavModel
                        delegate: ItemDelegate {
                            id: navTab
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            highlighted: root.currentPage === modelData.page
                            focusPolicy: Qt.StrongFocus
                            Accessible.name: modelData.a11y
                            Accessible.role: Accessible.Button
                            onClicked: root.navigateTo(modelData.page)

                            background: Rectangle {
                                color: "transparent"
                            }

                            contentItem: ColumnLayout {
                                spacing: 2
                                SvgIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: modelData.icon
                                    color: navTab.highlighted ? root.primaryColor : root.mutedColor
                                    size: 22
                                }
                                Label {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.label
                                    font.pixelSize: 10
                                    font.bold: navTab.highlighted
                                    color: navTab.highlighted ? root.primaryColor : root.mutedColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
