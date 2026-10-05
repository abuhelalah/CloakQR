import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: page
    title: qsTr("History")
    property bool wideLayout: false
    property color canvasColor: "#F1F5F3"
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#0B6B5E"
    property color mutedColor: "#4B5754"
    property color containerColor: "#D5EBE4"
    property color containerTextColor: "#053B33"
    property color errorColor: "#B3261E"
    readonly property bool dark: Material.theme === Material.Dark
    // The rail layout has no top bar, so the page shows its own title there.
    readonly property bool showTitle: ApplicationWindow.window !== null
                                      && ApplicationWindow.window.railLayout === true
    readonly property color dividerColor: dark ? Qt.rgba(1, 1, 1, 0.12) : "#E3E8E6"
    readonly property color tileColor: dark ? containerColor : "#EAF1EE"

    // "" (all), "scanned" or "generated"; applied to the shared filter proxy.
    property string originFilter: ""
    onOriginFilterChanged: scanHistoryFilter.setFilterFixedString(originFilter)

    // Emitted when the user taps a saved entry; the host reopens the scan
    // result dialog so its quick actions can be used again.
    signal itemActivated(string content)

    // Deferred history load: fetch rows the first time this tab is shown.
    Component.onCompleted: {
        scanHistoryFilter.setFilterFixedString(originFilter)
        if (visible)
            scanHistory.ensureLoaded()
    }
    onVisibleChanged: if (visible) scanHistory.ensureLoaded()

    // Month abbreviation for a date header (localised via qsTr).
    function monthAbbrev(monthIndex) {
        const names = [
            qsTr("Jan"), qsTr("Feb"), qsTr("Mar"), qsTr("Apr"),
            qsTr("May"), qsTr("Jun"), qsTr("Jul"), qsTr("Aug"),
            qsTr("Sep"), qsTr("Oct"), qsTr("Nov"), qsTr("Dec")
        ]
        return monthIndex >= 0 && monthIndex < names.length ? names[monthIndex] : ""
    }

    // Maps a "yyyy-MM-dd" day key to a human, localised section header.
    function daySectionLabel(key) {
        const today = Qt.formatDate(new Date(), "yyyy-MM-dd")
        const yesterday = Qt.formatDate(new Date(Date.now() - 86400000), "yyyy-MM-dd")
        if (key === today) return qsTr("Today")
        if (key === yesterday) return qsTr("Yesterday")
        const parts = (key || "").split("-")
        if (parts.length === 3)
            return parts[2] + " " + page.monthAbbrev(parseInt(parts[1], 10) - 1) + " " + parts[0]
        return key
    }

    background: Rectangle {
        color: page.canvasColor
    }

    ColumnLayout {
        width: Math.min(page.width, page.wideLayout ? 920 : 600)
        x: Math.max(0, (page.width - width) / 2)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: page.wideLayout ? 28 : 16
        spacing: 14

        // Tablet/desktop has no top bar, so the page carries its own title.
        Label {
            visible: page.showTitle
            Layout.leftMargin: 28
            text: qsTr("History")
            font.pixelSize: Math.round(28 * appSettings.fontScale)
            font.bold: true
        }

        // Local-storage banner with the entry count.
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: page.wideLayout ? 28 : 16
            Layout.rightMargin: page.wideLayout ? 28 : 16
            implicitHeight: bannerRow.implicitHeight + 24
            radius: 16
            color: page.containerColor

            RowLayout {
                id: bannerRow
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10
                SvgIcon {
                    source: "qrc:/icons/shield.svg"
                    color: page.containerTextColor
                    size: 20
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Stored only on this device, never synced")
                    color: page.containerTextColor
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                }
                Label {
                    text: scanHistory.count + " / " + scanHistory.maxEntries
                    color: page.containerTextColor
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: page.wideLayout ? 28 : 16
            Layout.rightMargin: page.wideLayout ? 28 : 16
            implicitHeight: banner.implicitHeight + 24
            visible: !appSettings.historyEnabled
            radius: 16
            color: page.dark ? "#4A3B12" : "#FFF3D6"

            Label {
                id: banner
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: Text.AlignVCenter
                text: qsTr("History is turned off. New scans will not be saved.")
                wrapMode: Text.WordWrap
                color: page.dark ? "#FFE2A0" : "#5D4037"
                Accessible.name: text
            }
        }

        // Filter (All / Scanned / Created) + Clear all.
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: page.wideLayout ? 28 : 16
            Layout.rightMargin: page.wideLayout ? 28 : 16
            spacing: 8

            SegmentedControl {
                Layout.fillWidth: true
                Layout.maximumWidth: 420
                model: [
                    { key: "",          label: qsTr("All") },
                    { key: "scanned",   label: qsTr("Scanned") },
                    { key: "generated", label: qsTr("Created") }
                ]
                currentKey: page.originFilter
                fillColor: page.surfaceColor
                selectedColor: page.containerColor
                selectedTextColor: page.containerTextColor
                textColor: page.mutedColor
                onActivated: (key) => page.originFilter = key
            }

            Item { Layout.fillWidth: true; visible: page.wideLayout }

            Button {
                id: clearButton
                flat: true
                enabled: scanHistory.count > 0
                Accessible.name: qsTr("Clear all history")
                onClicked: clearConfirm.open()
                contentItem: Label {
                    text: qsTr("Clear all")
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: page.errorColor
                    opacity: clearButton.enabled ? 1 : 0.4
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        ListView {
            id: historyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: page.wideLayout ? 28 : 16
            Layout.rightMargin: page.wideLayout ? 28 : 16
            bottomMargin: 24
            spacing: 0
            clip: true
            // Recycle delegate items while scrolling so each row's SvgIcon is
            // reused instead of re-created — the tint is then re-applied only
            // when the row's content type changes, not on every scroll tick.
            reuseItems: true
            model: scanHistoryFilter

            section.property: "dayKey"
            section.criteria: ViewSection.FullString
            section.delegate: Item {
                required property string section
                width: historyList.width
                height: 38

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    text: page.daySectionLabel(parent.section)
                    font.pixelSize: Math.round(13 * appSettings.fontScale)
                    font.bold: true
                    color: page.mutedColor
                }
            }

            delegate: ItemDelegate {
                id: historyDelegate
                width: historyList.width
                hoverEnabled: true
                topPadding: 12
                bottomPadding: 12
                leftPadding: 14
                rightPadding: 6
                Accessible.name: model.content
                onClicked: page.itemActivated(model.content)

                // Rows of one day form a single rounded card.
                readonly property bool firstInDay: ListView.previousSection !== ListView.section
                readonly property bool lastInDay: ListView.nextSection !== ListView.section
                readonly property color fill: historyDelegate.pressed
                    ? Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.14)
                    : historyDelegate.hovered
                        ? Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.07)
                        : page.surfaceColor

                background: Item {
                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: historyDelegate.fill
                    }
                    Rectangle {
                        visible: !historyDelegate.firstInDay
                        width: parent.width
                        height: 20
                        color: historyDelegate.fill
                    }
                    Rectangle {
                        visible: !historyDelegate.lastInDay
                        width: parent.width
                        height: 20
                        y: parent.height - height
                        color: historyDelegate.fill
                    }
                    Rectangle {
                        visible: !historyDelegate.firstInDay
                        width: parent.width
                        height: 1
                        color: page.dividerColor
                    }
                }

                function typeIcon(type) {
                    switch (type) {
                    case "url":       return "qrc:/icons/url.svg"
                    case "wifi":      return "qrc:/icons/wifi.svg"
                    case "email":     return "qrc:/icons/email.svg"
                    case "tel":       return "qrc:/icons/phone.svg"
                    case "sms":       return "qrc:/icons/sms.svg"
                    case "geo":       return "qrc:/icons/location.svg"
                    case "vcard":     return "qrc:/icons/contact.svg"
                    case "otp":       return "qrc:/icons/key.svg"
                    case "calendar":  return "qrc:/icons/calendar.svg"
                    case "sepa":      return "qrc:/icons/bank.svg"
                    case "whatsapp":  return "qrc:/icons/chat.svg"
                    case "telegram":  return "qrc:/icons/send.svg"
                    case "signal":    return "qrc:/icons/lock.svg"
                    case "facetime":  return "qrc:/icons/video.svg"
                    case "messenger": return "qrc:/icons/chat.svg"
                    case "bitcoin":   return "qrc:/icons/money.svg"
                    case "ethereum":  return "qrc:/icons/money.svg"
                    case "upi":       return "qrc:/icons/money.svg"
                    case "paypal":    return "qrc:/icons/money.svg"
                    case "store":     return "qrc:/icons/store.svg"
                    case "encrypted": return "qrc:/icons/lock.svg"
                    default:          return "qrc:/icons/text.svg"
                    }
                }

                contentItem: RowLayout {
                    spacing: 12

                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: 12
                        color: page.tileColor
                        SvgIcon {
                            anchors.centerIn: parent
                            source: historyDelegate.typeIcon(model.contentType)
                            color: page.primaryColor
                            size: 20
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            Layout.fillWidth: true
                            text: model.content
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.pixelSize: Math.round(15 * appSettings.fontScale)
                            font.weight: Font.Medium
                        }
                        Label {
                            Layout.fillWidth: true
                            text: model.displayTime + " · "
                                  + (model.origin === "generated" ? qsTr("Created") : qsTr("Scanned"))
                            font.pixelSize: Math.round(13 * appSettings.fontScale)
                            color: page.mutedColor
                        }
                    }

                    ToolButton {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        Accessible.name: qsTr("Delete entry")
                        onClicked: scanHistory.removeEntry(
                            scanHistoryFilter.mapToSource(scanHistoryFilter.index(index, 0)).row)
                        contentItem: Item {
                            SvgIcon {
                                anchors.centerIn: parent
                                source: "qrc:/icons/trash.svg"
                                color: page.mutedColor
                                size: 20
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 48
                width: Math.min(parent.width, 280)
                visible: historyList.count === 0
                spacing: 12

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: 32
                    color: page.containerColor
                    SvgIcon {
                        anchors.centerIn: parent
                        source: "qrc:/icons/nav_history.svg"
                        color: page.primaryColor
                        size: 26
                    }
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: scanHistory.count === 0 ? qsTr("No history yet") : qsTr("Nothing here yet")
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Codes you scan or create will appear here.")
                    color: page.mutedColor
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    ConfirmDialog {
        id: clearConfirm
        message: (scanHistory === null || scanHistory.count === 0)
            ? qsTr("Delete all saved scans? This cannot be undone.")
            : scanHistory.count === 1
                ? qsTr("Delete this saved scan? This cannot be undone.")
                : qsTr("Delete %1 saved scans? This cannot be undone.").arg(scanHistory.count)
        confirmText: qsTr("Delete all")
        onConfirmed: scanHistory.clear()
    }
}
