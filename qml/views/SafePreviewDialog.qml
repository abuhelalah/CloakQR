import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Modern, robust popup shown after a QR code is scanned. It never opens links
// automatically: for web links it shows the destination host and requires an
// explicit tap on "Open link", preserving the safe-preview privacy guarantee.
Popup {
    id: dialog

    property string content: ""
    property color surfaceColor: "#FFFFFF"
    property color primaryColor: "#086C5C"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#5D6F69"
    property color accentColor: "#C84F2D"
    property bool passwordRevealed: false

    function show(text) {
        dialog.passwordRevealed = false
        dialog.content = text
        dialog.open()
    }

    readonly property bool isUrl: /^https?:\/\//i.test(content)
    readonly property bool isWifi: /^WIFI:/i.test(content)
    readonly property var wifi: parseWifi(content)

    // Recognises app-store deep links so the action button can offer to open
    // the relevant store. Qt.openUrlExternally already routes these to the
    // installed store app on the device.
    readonly property bool isAppleStore: /apps\.apple\.com|itunes\.apple\.com/i.test(content)
    readonly property bool isStoreLink: /^market:\/\//i.test(content)
        || /^https?:\/\/(play\.google\.com|apps\.apple\.com|itunes\.apple\.com)\//i.test(content)
    readonly property string openLabel: isStoreLink
        ? (isAppleStore ? qsTr("Open in App Store") : qsTr("Open in Play Store"))
        : qsTr("Open link")

    // Parses a "WIFI:S:ssid;T:WPA;P:pass;H:true;;" payload into its parts,
    // honouring the backslash escaping defined by the Wi-Fi QR convention.
    function parseWifi(payload) {
        var info = { ssid: "", security: "", password: "", hidden: false }
        if (!/^WIFI:/i.test(payload))
            return info
        var body = payload.substring(5)
        var tokens = []
        var cur = ""
        for (var i = 0; i < body.length; ++i) {
            var ch = body.charAt(i)
            if (ch === "\\" && i + 1 < body.length) {
                cur += body.charAt(i + 1)
                ++i
                continue
            }
            if (ch === ";") {
                tokens.push(cur)
                cur = ""
                continue
            }
            cur += ch
        }
        if (cur.length > 0)
            tokens.push(cur)
        for (var t = 0; t < tokens.length; ++t) {
            var tok = tokens[t]
            if (tok.length < 2 || tok.charAt(1) !== ":")
                continue
            var key = tok.charAt(0).toUpperCase()
            var val = tok.substring(2)
            if (key === "S") info.ssid = val
            else if (key === "T") info.security = val
            else if (key === "P") info.password = val
            else if (key === "H") info.hidden = (val.toLowerCase() === "true")
        }
        return info
    }

    readonly property string urlHost: {
        const match = content.match(/^https?:\/\/([^/?#]+)/i)
        return match ? match[1] : ""
    }
    readonly property string kindLabel: {
        if (isUrl) return qsTr("Website link")
        if (/^WIFI:/i.test(content)) return qsTr("Wi-Fi network")
        if (/^mailto:/i.test(content)) return qsTr("Email address")
        if (/^(tel|sms|smsto):/i.test(content)) return qsTr("Phone number")
        if (/^BEGIN:VCARD/i.test(content)) return qsTr("Contact card")
        if (/^(geo:|MATMSG:)/i.test(content)) return qsTr("Location")
        return qsTr("Plain text")
    }
    readonly property string kindGlyph: {
        if (isUrl) return "🔗"
        if (/^WIFI:/i.test(content)) return "📶"
        if (/^mailto:/i.test(content)) return "✉️"
        if (/^(tel|sms|smsto):/i.test(content)) return "📞"
        if (/^BEGIN:VCARD/i.test(content)) return "👤"
        return "📄"
    }

    parent: Overlay.overlay
    anchors.centerIn: Overlay.overlay
    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 0
    width: Math.min((Overlay.overlay ? Overlay.overlay.width : 400) - 48, 480)

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.55)
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150 }
            NumberAnimation { property: "scale"; from: 0.92; to: 1.0; duration: 180; easing.type: Easing.OutBack }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: 120 }
        }
    }

    background: Rectangle {
        color: dialog.surfaceColor
        radius: 16
        border.width: 1
        border.color: Qt.rgba(dialog.mutedColor.r, dialog.mutedColor.g, dialog.mutedColor.b, 0.16)
    }

    // Hidden helper used to place the scanned content on the clipboard.
    TextEdit {
        id: clipboardHelper
        visible: false
        function copyText(value) {
            text = value
            selectAll()
            copy()
            deselect()
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: dialog.primaryColor
            topLeftRadius: 16
            topRightRadius: 16

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 10
                spacing: 12

                Label {
                    text: dialog.kindGlyph
                    font.pixelSize: 22
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        text: qsTr("Scan result")
                        color: dialog.primaryTextColor
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Label {
                        text: dialog.kindLabel
                        color: Qt.rgba(dialog.primaryTextColor.r, dialog.primaryTextColor.g, dialog.primaryTextColor.b, 0.82)
                        font.pixelSize: 11
                    }
                }
                ToolButton {
                    id: closeButton
                    implicitWidth: 40
                    implicitHeight: 40
                    Accessible.name: qsTr("Close")
                    onClicked: dialog.close()
                    contentItem: Label {
                        text: "\u00D7"
                        color: dialog.primaryTextColor
                        font.pixelSize: 28
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: closeButton.pressed ? Qt.rgba(1, 0.36, 0.36, 0.55)
                             : closeButton.hovered ? Qt.rgba(1, 0.36, 0.36, 0.32)
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 18
            spacing: 14

            RowLayout {
                visible: dialog.isUrl
                Layout.fillWidth: true
                spacing: 8
                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: dialog.accentColor
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Opens %1").arg(dialog.urlHost)
                    color: dialog.mutedColor
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            // Structured view for Wi-Fi credentials.
            ColumnLayout {
                visible: dialog.isWifi
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: qsTr("Network")
                    color: dialog.mutedColor
                    font.pixelSize: 11
                }
                Label {
                    Layout.fillWidth: true
                    text: dialog.wifi.ssid
                    color: Material.foreground
                    font.pixelSize: 17
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: {
                        var sec = dialog.wifi.security
                        var label = (!sec || sec.toUpperCase() === "NOPASS")
                            ? qsTr("Open network")
                            : qsTr("Security: %1").arg(sec.toUpperCase())
                        if (dialog.wifi.hidden)
                            label += " \u00B7 " + qsTr("Hidden")
                        return label
                    }
                    color: dialog.mutedColor
                    font.pixelSize: 12
                }

                RowLayout {
                    visible: dialog.wifi.password.length > 0
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 8

                    Label {
                        Layout.fillWidth: true
                        text: dialog.passwordRevealed
                            ? dialog.wifi.password
                            : "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022"
                        color: Material.foreground
                        font.pixelSize: 15
                        font.family: "monospace"
                        elide: Text.ElideRight
                    }
                    Button {
                        flat: true
                        text: dialog.passwordRevealed ? qsTr("Hide") : qsTr("Show")
                        onClicked: dialog.passwordRevealed = !dialog.passwordRevealed
                    }
                    Button {
                        flat: true
                        text: qsTr("Copy")
                        Accessible.name: qsTr("Copy password")
                        onClicked: {
                            clipboardHelper.copyText(dialog.wifi.password)
                            hint.flash(qsTr("Copied to clipboard"))
                        }
                    }
                }
            }

            Rectangle {
                visible: !dialog.isWifi
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentText.implicitHeight + 20, 240)
                radius: 10
                color: Qt.rgba(dialog.mutedColor.r, dialog.mutedColor.g, dialog.mutedColor.b, 0.10)

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true
                    background: null

                    TextArea {
                        id: contentText
                        text: dialog.content
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.WrapAnywhere
                        textFormat: TextEdit.PlainText
                        color: Material.foreground
                        background: null
                        padding: 0
                    }
                }
            }

            Label {
                id: hint
                property string message: qsTr("Copied to clipboard")
                text: message
                color: dialog.primaryColor
                font.pixelSize: 12
                opacity: 0
                Layout.fillWidth: true

                function flash(msg) {
                    message = msg
                    opacity = 1
                    hideTimer.restart()
                }

                Behavior on opacity { NumberAnimation { duration: 160 } }

                Timer {
                    id: hideTimer
                    interval: 1500
                    onTriggered: hint.opacity = 0
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    flat: true
                    text: qsTr("Close")
                    Accessible.name: qsTr("Close")
                    onClicked: dialog.close()
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Copy")
                    Accessible.name: qsTr("Copy scanned content")
                    onClicked: {
                        clipboardHelper.copyText(dialog.content)
                        hint.flash(qsTr("Copied to clipboard"))
                    }
                }
                Button {
                    visible: dialog.isWifi
                        ? platformBridge.wifiConnectSupported
                        : dialog.isUrl
                    Material.background: dialog.primaryColor
                    Material.foreground: dialog.primaryTextColor
                    text: dialog.isWifi ? qsTr("Connect") : dialog.openLabel
                    Accessible.name: text
                    onClicked: {
                        if (dialog.isWifi) {
                            var ok = platformBridge.connectToWifi(
                                dialog.wifi.ssid, dialog.wifi.password,
                                dialog.wifi.security, dialog.wifi.hidden)
                            if (!ok)
                                hint.flash(qsTr("Couldn't start Wi-Fi connection"))
                        } else {
                            Qt.openUrlExternally(dialog.content)
                        }
                    }
                }
            }
        }
    }
}
