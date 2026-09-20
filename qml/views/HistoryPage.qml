import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Page {
    id: page
    title: qsTr("History")
    property bool wideLayout: false
    property color canvasColor: "#F3F7F5"
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#086C5C"
    property color mutedColor: "#5D6F69"

    // Emitted when the user taps a saved entry; the host reopens the scan
    // result dialog so its quick actions can be used again.
    signal itemActivated(string content)

    // Deferred history load: fetch rows the first time this tab is shown.
    Component.onCompleted: if (visible) scanHistory.ensureLoaded()
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
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: page.wideLayout ? 28 : 20
            Layout.rightMargin: page.wideLayout ? 28 : 20
            Layout.topMargin: page.wideLayout ? 28 : 20
            Layout.bottomMargin: 16
            spacing: 4

            Label {
                text: qsTr("Scan history")
                font.pixelSize: Math.round((page.wideLayout ? 28 : 23) * appSettings.fontScale)
                font.bold: true
            }
            Label {
                text: qsTr("Recent codes stored only on this device")
                color: page.mutedColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // Local-storage info banner.
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: page.wideLayout ? 28 : 20
            Layout.rightMargin: page.wideLayout ? 28 : 20
            Layout.bottomMargin: 12
            implicitHeight: localBannerLabel.implicitHeight + 16
            radius: 9
            color: Qt.rgba(page.primaryColor.r, page.primaryColor.g, page.primaryColor.b, 0.10)

            Row {
                anchors.centerIn: parent
                spacing: 8
                SvgIcon {
                    source: "qrc:/icons/shield.svg"
                    color: page.primaryColor
                    size: 16
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    id: localBannerLabel
                    text: qsTr("Stored locally, never synced")
                    color: page.primaryColor
                    font.pixelSize: 12
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? banner.implicitHeight + 16 : 0
            visible: !appSettings.historyEnabled
            color: Material.color(Material.Amber, Material.Shade100)

            Label {
                id: banner
                anchors.fill: parent
                anchors.margins: 8
                text: qsTr("History is turned off. New scans will not be saved.")
                wrapMode: Text.WordWrap
                color: "#5D4037"
                Accessible.name: text
            }
        }

        ListView {
            id: historyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            spacing: 6
            clip: true
            // Recycle delegate items while scrolling so each row's SvgIcon
            // (Image + ColorOverlay) is reused instead of re-created — the
            // offscreen tint is then re-rendered only when the row's content
            // type actually changes, not on every scroll tick.
            reuseItems: true
            model: scanHistory

            section.property: "dayKey"
            section.criteria: ViewSection.FullString
            section.delegate: Rectangle {
                width: parent.width
                height: 32
                color: "transparent"

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.daySectionLabel(section)
                    font.pixelSize: Math.round(12 * appSettings.fontScale)
                    font.bold: true
                    color: page.mutedColor
                }
            }

            delegate: ItemDelegate {
                id: historyDelegate
                width: historyList.width
                hoverEnabled: true
                Accessible.name: model.content
                onClicked: page.itemActivated(model.content)

                background: Rectangle {
                    color: historyDelegate.pressed
                        ? Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.18)
                        : historyDelegate.hovered
                            ? Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.10)
                            : page.surfaceColor
                    radius: 6
                    Behavior on color { ColorAnimation { duration: 120 } }
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

                contentItem: ColumnLayout {
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        SvgIcon {
                            source: typeIcon(model.contentType)
                            color: Material.foreground
                            size: 18
                        }

                        Label {
                            text: model.content
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: Math.round(14 * appSettings.fontScale)
                        }

                        ToolButton {
                            Accessible.name: qsTr("Delete entry")
                            onClicked: scanHistory.removeEntry(index)
                            contentItem: Item {
                                SvgIcon {
                                    anchors.centerIn: parent
                                    source: "qrc:/icons/trash.svg"
                                    color: page.mutedColor
                                    size: 16
                                }
                            }
                        }
                    }

                    Label {
                        text: model.displayTime + " • "
                              + (model.origin === "generated" ? qsTr("Generated") : qsTr("Scanned"))
                        font.pixelSize: Math.round(11 * appSettings.fontScale)
                        opacity: 0.6
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: historyList.count === 0
                text: qsTr("No scans yet")
                opacity: 0.5
            }
        }
    }

    footer: Pane {
        padding: page.wideLayout ? 16 : 12
        Material.elevation: 0

        background: Rectangle {
            color: page.surfaceColor

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.22)
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Item { Layout.fillWidth: true }

            Button {
                id: clearButton
                enabled: scanHistory !== null && scanHistory.count > 0
                Accessible.name: qsTr("Clear all history")
                onClicked: clearConfirm.open()
                flat: true

                readonly property color dangerColor: "#D32F2F"

                Layout.preferredHeight: 40
                leftPadding: 10
                rightPadding: 10

                opacity: clearButton.enabled ? 1.0 : 0.4
                Behavior on opacity { NumberAnimation { duration: 120 } }

                contentItem: Label {
                    text: qsTr("Clear all")
                    font.pixelSize: Math.round(13 * appSettings.fontScale)
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.8
                    color: clearButton.enabled ? clearButton.dangerColor : page.mutedColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
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
