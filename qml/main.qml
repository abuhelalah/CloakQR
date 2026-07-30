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

    readonly property var navModel: {
        var items = [
            { page: 0, label: qsTr("Scan"), a11y: qsTr("Scanner"), group: 0 },
            { page: 1, label: qsTr("Create"), a11y: qsTr("Create QR code"), group: 0 }
        ]
        if (appEngine.paidEdition) {
            items.push({ page: 4, label: qsTr("Design Studio"), a11y: qsTr("Design Studio"), group: 1 })
            items.push({ page: 5, label: qsTr("Batch Studio"), a11y: qsTr("Batch Studio"), group: 1 })
        }
        items.push({ page: 2, label: qsTr("History"), a11y: qsTr("History"), group: 2 })
        items.push({ page: 3, label: qsTr("Settings"), a11y: qsTr("Settings"), group: 2 })
        items.push({ page: 6, label: qsTr("About"), a11y: qsTr("About"), group: 3 })
        return items
    }

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
                return navModel[i].label
        return ""
    }

    function navigateTo(index) {
        if (index >= 0 && index < pageStack.count)
            root.currentPage = index
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

    RowLayout {
        anchors.fill: parent
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
                            text: modelData.label
                            highlighted: root.currentPage === modelData.page
                            Accessible.name: modelData.a11y
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
                        text: qsTr("No tracking · v0.3")
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
                    anchors.leftMargin: 6
                    anchors.rightMargin: 16
                    spacing: 6

                    AbstractButton {
                        id: menuButton
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        readonly property bool active: navDrawer.opened
                        Accessible.name: qsTr("Open navigation menu")
                        onClicked: navDrawer.opened ? navDrawer.close() : navDrawer.open()

                        contentItem: Item {
                            Rectangle {
                                width: 24
                                height: 2.5
                                radius: 1.25
                                color: root.primaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: menuButton.active ? (parent.height - height) / 2 : parent.height / 2 - 7
                                rotation: menuButton.active ? 45 : 0
                                Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }
                                Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }
                            }
                            Rectangle {
                                width: 24
                                height: 2.5
                                radius: 1.25
                                color: root.primaryColor
                                anchors.centerIn: parent
                                opacity: menuButton.active ? 0 : 1
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                            Rectangle {
                                width: 24
                                height: 2.5
                                radius: 1.25
                                color: root.primaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: menuButton.active ? (parent.height - height) / 2 : parent.height / 2 + 5
                                rotation: menuButton.active ? -45 : 0
                                Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }
                                Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.InOutQuad } }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            Layout.fillWidth: true
                            text: root.currentTitle()
                            font.bold: true
                            font.pixelSize: 18
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: appEngine.paidEdition ? qsTr("CloakQR Pro") : qsTr("CloakQR")
                            color: root.mutedColor
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 9
                        Layout.preferredHeight: 9
                        radius: 4.5
                        color: root.primaryColor
                    }
                }
            }

            StackLayout {
                id: pageStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPage

                ScannerPage {
                    wideLayout: !root.compactLayout
                    canvasColor: root.canvasColor
                    surfaceColor: root.surfaceColor
                    primaryColor: root.primaryColor
                    primaryTextColor: root.primaryTextColor
                    mutedColor: root.mutedColor
                    accentColor: root.accentColor
                }
                GeneratorPage {
                    wideLayout: !root.compactLayout
                    canvasColor: root.canvasColor
                    primaryColor: root.primaryColor
                    primaryTextColor: root.primaryTextColor
                    mutedColor: root.mutedColor
                }
                HistoryPage {
                    wideLayout: !root.compactLayout
                    canvasColor: root.canvasColor
                    surfaceColor: root.surfaceColor
                    mutedColor: root.mutedColor
                }
                SettingsPage {
                    wideLayout: !root.compactLayout
                    canvasColor: root.canvasColor
                    primaryColor: root.primaryColor
                    mutedColor: root.mutedColor
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
                AboutPage {
                    wideLayout: !root.compactLayout
                    canvasColor: root.canvasColor
                    surfaceColor: root.surfaceColor
                    primaryColor: root.primaryColor
                    mutedColor: root.mutedColor
                }
            }

        }
    }

    Drawer {
        id: navDrawer
        edge: Qt.application.layoutDirection === Qt.RightToLeft ? Qt.RightEdge : Qt.LeftEdge
        width: Math.min(300, root.width * 0.82)
        height: root.height
        interactive: !root.railLayout
        Material.background: root.surfaceColor

        onOpened: if (root.railLayout) close()

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 96
                color: root.primaryColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 2
                    Item { Layout.fillHeight: true }
                    Label {
                        text: appEngine.paidEdition ? qsTr("CloakQR Pro") : qsTr("CloakQR")
                        color: appSettings.darkMode ? "#0E1715" : "#FFFFFF"
                        font.bold: true
                        font.pixelSize: 20
                    }
                    Label {
                        text: qsTr("Private by design")
                        color: appSettings.darkMode ? "#0E1715" : "#EAF7F3"
                        font.pixelSize: 12
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.navModel
                delegate: Column {
                    required property var modelData
                    required property int index
                    width: ListView.view.width

                    MenuSeparator {
                        width: parent.width
                        visible: index > 0
                            && modelData.group !== root.navModel[index - 1].group
                    }
                    ItemDelegate {
                        width: parent.width
                        text: modelData.label
                        highlighted: root.currentPage === modelData.page
                        Accessible.name: modelData.a11y
                        onClicked: {
                            root.navigateTo(modelData.page)
                            navDrawer.close()
                        }
                    }
                }
            }
        }
    }
}
