import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
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

    // Holds the contact being saved to a .vcf while the desktop file dialog is
    // open (Android uses the OS contact screen instead).
    property string pendingName: ""
    property string pendingPhone: ""
    property string pendingEmail: ""

    function show(text) {
        dialog.passwordRevealed = false
        dialog.content = text
        dialog.open()
    }

    // Ordered recognisers — first match wins. Deep links are listed before the
    // generic URL rule so each is labelled by its target app. An entry is a
    // [kind, regex] pair; supporting a new scheme is a one-line addition here.
    readonly property var recognisers: [
        ["wifi",      /^WIFI:/i],
        ["email",     /^mailto:|^MATMSG:/i],
        ["email",     /^[^\s@]+@[^\s@]+\.[^\s@]+$/],
        ["tel",       /^tel:/i],
        ["sms",       /^(sms|smsto):/i],
        ["geo",       /^geo:/i],
        ["vcard",     /^(BEGIN:VCARD|MECARD:)/i],
        ["otp",       /^otpauth:\/\//i],
        ["calendar",  /^BEGIN:VCALENDAR/i],
        ["sepa",      /^BCD\r?\n/],
        ["whatsapp",  /^whatsapp:\/\//i],
        ["whatsapp",  /^https:\/\/(wa\.me|api\.whatsapp\.com)\//i],
        ["telegram",  /^tg:\/\//i],
        ["telegram",  /^https:\/\/t\.me\//i],
        ["signal",    /^sgnl:\/\//i],
        ["signal",    /^https:\/\/signal\.me\//i],
        ["facetime",  /^facetime(-audio)?:/i],
        ["messenger", /^fb-messenger:\/\//i],
        ["bitcoin",   /^bitcoin:/i],
        ["ethereum",  /^ethereum:/i],
        ["upi",       /^upi:\/\//i],
        ["paypal",    /^https:\/\/(www\.)?paypal\.me\//i],
        ["store",     /^market:\/\//i],
        ["store",     /^https?:\/\/(play\.google\.com|apps\.apple\.com|itunes\.apple\.com)\//i],
        ["url",       /^https?:\/\//i]
    ]

    // Single classification pass over the scanned payload.
    function detectKind(text) {
        for (var i = 0; i < recognisers.length; ++i) {
            if (recognisers[i][1].test(text))
                return recognisers[i][0]
        }
        return "text"
    }

    readonly property string kind: detectKind(content)

    // Derived type flags consumed by the views and action buttons.
    readonly property bool isUrl: kind === "url"
    readonly property bool isWifi: kind === "wifi"
    readonly property bool isEmail: kind === "email"
    readonly property bool isTel: kind === "tel"
    readonly property bool isSms: kind === "sms"
    readonly property bool isGeo: kind === "geo"
    readonly property bool isVCard: kind === "vcard"
    readonly property bool isOtp: kind === "otp"
    readonly property bool isCalendar: kind === "calendar"
    readonly property bool isSepa: kind === "sepa"
    readonly property bool isStoreLink: kind === "store"

    // True when the current platform can hand a new contact to the OS or, on
    // desktop, when we can offer to save the contact as a .vcf file.
    readonly property bool isMobile: Qt.platform.os === "android" || Qt.platform.os === "ios"

    // Parsed data for the structured types (each parser no-ops for other kinds).
    readonly property var wifi: parseWifi(content)
    readonly property var emailData: parseEmail(content)
    readonly property string telNumber: isTel ? content.substring(4) : ""
    readonly property var sms: parseSms(content)
    readonly property var geo: parseGeo(content)
    readonly property var vcard: parseVCard(content)
    readonly property var otp: parseOtp(content)
    readonly property var calendar: parseCalendar(content)

    // App-store links are deep links too; the button just names the store.
    readonly property bool isAppleStore: /apps\.apple\.com|itunes\.apple\.com/i.test(content)

    // Kinds whose primary action is handing the payload to the OS.
    readonly property bool isOpenable: kind === "url" || kind === "store"
        || kind === "whatsapp" || kind === "telegram" || kind === "signal"
        || kind === "facetime" || kind === "messenger" || kind === "bitcoin"
        || kind === "ethereum" || kind === "upi" || kind === "paypal"

    // Label for the single "open" action, named after the target app.
    readonly property string openLabel: {
        switch (kind) {
        case "whatsapp":  return qsTr("Open in WhatsApp")
        case "telegram":  return qsTr("Open in Telegram")
        case "signal":    return qsTr("Open in Signal")
        case "facetime":  return qsTr("Start FaceTime")
        case "messenger": return qsTr("Open in Messenger")
        case "bitcoin":   return qsTr("Open wallet")
        case "ethereum":  return qsTr("Open wallet")
        case "upi":       return qsTr("Pay via UPI")
        case "paypal":    return qsTr("Open in PayPal")
        case "store":     return isAppleStore ? qsTr("Open in App Store") : qsTr("Open in Play Store")
        default:          return qsTr("Open link")
        }
    }

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

    // Recognises an email QR in any common form — a "mailto:" URI, the legacy
    // "MATMSG:" format, or a bare address — and extracts address/subject/body.
    function parseEmail(payload) {
        var info = { isEmail: false, address: "", subject: "", body: "" }
        var p = (payload || "").trim()
        if (/^mailto:/i.test(p)) {
            info.isEmail = true
            var rest = p.substring(7)
            var q = rest.indexOf("?")
            if (q >= 0) {
                info.address = decodeURIComponent(rest.substring(0, q))
                var query = rest.substring(q + 1)
                var sm = query.match(/subject=([^&]*)/i)
                var bm = query.match(/body=([^&]*)/i)
                if (sm) info.subject = decodeURIComponent(sm[1].replace(/\+/g, " "))
                if (bm) info.body = decodeURIComponent(bm[1].replace(/\+/g, " "))
            } else {
                info.address = decodeURIComponent(rest)
            }
        } else if (/^MATMSG:/i.test(p)) {
            info.isEmail = true
            var to = p.match(/TO:((?:\\.|[^;])*)/i)
            var sub = p.match(/SUB:((?:\\.|[^;])*)/i)
            var bod = p.match(/BODY:((?:\\.|[^;])*)/i)
            if (to) info.address = to[1].replace(/\\(.)/g, "$1")
            if (sub) info.subject = sub[1].replace(/\\(.)/g, "$1")
            if (bod) info.body = bod[1].replace(/\\(.)/g, "$1")
        } else if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(p)) {
            info.isEmail = true
            info.address = p
        }
        return info
    }

    // Assembles a "mailto:" URI with the subject and body percent-encoded so the
    // email app opens a pre-filled draft.
    function buildMailto(d) {
        var uri = "mailto:" + d.address
        var q = []
        if (d.subject.length > 0)
            q.push("subject=" + encodeURIComponent(d.subject))
        if (d.body.length > 0)
            q.push("body=" + encodeURIComponent(d.body))
        if (q.length > 0)
            uri += "?" + q.join("&")
        return uri
    }

    // Splits an "SMSTO:number:message" or "sms:number?body=..." payload.
    function parseSms(payload) {
        var info = { number: "", message: "" }
        if (/^smsto:/i.test(payload)) {
            var rest = payload.substring(6)
            var idx = rest.indexOf(":")
            if (idx >= 0) {
                info.number = rest.substring(0, idx)
                info.message = rest.substring(idx + 1)
            } else {
                info.number = rest
            }
        } else if (/^sms:/i.test(payload)) {
            var body = payload.substring(4)
            var q = body.indexOf("?")
            if (q >= 0) {
                info.number = body.substring(0, q)
                var m = body.substring(q + 1).match(/body=([^&]*)/i)
                if (m)
                    info.message = decodeURIComponent(m[1].replace(/\+/g, " "))
            } else {
                info.number = body
            }
        }
        return info
    }

    // Parses an "otpauth://TYPE/LABEL?secret=..." URI into its parts. The
    // label may embed the issuer as "Issuer:account" and/or carry an issuer=.
    function parseOtp(payload) {
        var info = { type: "", account: "", issuer: "", secret: "",
                     algorithm: "", digits: "", period: "" }
        if (!/^otpauth:\/\//i.test(payload))
            return info
        var rest = payload.substring(10)
        var q = rest.indexOf("?")
        var path = q >= 0 ? rest.substring(0, q) : rest
        var query = q >= 0 ? rest.substring(q + 1) : ""

        var slash = path.indexOf("/")
        if (slash >= 0) {
            info.type = path.substring(0, slash).toLowerCase()
            var label = decodeURIComponent(path.substring(slash + 1))
            var colon = label.indexOf(":")
            if (colon >= 0) {
                info.issuer = label.substring(0, colon)
                info.account = label.substring(colon + 1)
            } else {
                info.account = label
            }
        }

        var params = query.split("&")
        for (var i = 0; i < params.length; ++i) {
            var eq = params[i].indexOf("=")
            if (eq < 0)
                continue
            var key = params[i].substring(0, eq).toLowerCase()
            var val = decodeURIComponent(params[i].substring(eq + 1).replace(/\+/g, " "))
            if (key === "secret") info.secret = val
            else if (key === "issuer") info.issuer = val
            else if (key === "algorithm") info.algorithm = val
            else if (key === "digits") info.digits = val
            else if (key === "period") info.period = val
        }
        return info
    }

    // Converts an iCalendar date value ("20260116T090000Z", "20260116T090000"
    // or date-only "20260116") to epoch milliseconds. Returns 0 on failure.
    function icalToMillis(value) {
        var m = value.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2}))?(Z)?$/)
        if (!m)
            return 0
        var year = parseInt(m[1], 10)
        var month = parseInt(m[2], 10) - 1
        var day = parseInt(m[3], 10)
        var hour = m[4] ? parseInt(m[4], 10) : 0
        var min = m[5] ? parseInt(m[5], 10) : 0
        var sec = m[6] ? parseInt(m[6], 10) : 0
        return m[7] ? Date.UTC(year, month, day, hour, min, sec)
                    : new Date(year, month, day, hour, min, sec).getTime()
    }

    // Extracts the summary, description, location and start/end times from an
    // iCalendar payload, unfolding continuation lines and skipping parameters.
    function parseCalendar(payload) {
        var info = { title: "", description: "", location: "", start: 0, end: 0 }
        if (!/^BEGIN:VCALENDAR/i.test(payload))
            return info
        var lines = payload.split(/\r?\n/)
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i]
            while (i + 1 < lines.length && /^[ \t]/.test(lines[i + 1]))
                line += lines[++i].substring(1)
            var colon = line.indexOf(":")
            if (colon < 0)
                continue
            var key = line.substring(0, colon).toUpperCase().split(";")[0]
            var val = line.substring(colon + 1).trim()
            if (key === "SUMMARY" && info.title.length === 0) info.title = val
            else if (key === "DESCRIPTION" && info.description.length === 0) info.description = val
            else if (key === "LOCATION" && info.location.length === 0) info.location = val
            else if (key === "DTSTART" && info.start === 0) info.start = icalToMillis(val)
            else if (key === "DTEND" && info.end === 0) info.end = icalToMillis(val)
        }
        return info
    }

    // Parses "geo:lat,lon" with an optional "?q=label" query.
    function parseGeo(payload) {
        var info = { lat: "", lon: "", label: "" }
        if (!/^geo:/i.test(payload))
            return info
        var body = payload.substring(4)
        var q = body.indexOf("?")
        var query = ""
        if (q >= 0) {
            query = body.substring(q + 1)
            body = body.substring(0, q)
        }
        var coords = body.split(",")
        if (coords.length >= 2) {
            info.lat = coords[0]
            info.lon = coords[1]
        }
        var lm = query.match(/q=([^&]*)/i)
        if (lm)
            info.label = decodeURIComponent(lm[1].replace(/\+/g, " "))
        return info
    }

    // Extracts the display name, first phone and first email from a vCard or
    // the more compact MECARD contact format.
    function parseVCard(payload) {
        var info = { name: "", phone: "", email: "" }
        if (/^MECARD:/i.test(payload)) {
            var mbody = payload.substring(7)
            var mtokens = []
            var mcur = ""
            for (var mi = 0; mi < mbody.length; ++mi) {
                var mch = mbody.charAt(mi)
                if (mch === "\\" && mi + 1 < mbody.length) {
                    mcur += mbody.charAt(mi + 1)
                    ++mi
                    continue
                }
                if (mch === ";") {
                    mtokens.push(mcur)
                    mcur = ""
                    continue
                }
                mcur += mch
            }
            if (mcur.length > 0)
                mtokens.push(mcur)
            for (var mt = 0; mt < mtokens.length; ++mt) {
                var mtok = mtokens[mt]
                var mcolon = mtok.indexOf(":")
                if (mcolon < 0)
                    continue
                var mkey = mtok.substring(0, mcolon).toUpperCase()
                var mval = mtok.substring(mcolon + 1)
                if (mkey === "N" && info.name.length === 0) {
                    // MECARD names are "Last,First"; show them in reading order.
                    var parts = mval.split(",")
                    info.name = parts.length > 1
                        ? (parts[1] + " " + parts[0]).trim()
                        : mval.trim()
                } else if (mkey === "TEL" && info.phone.length === 0) {
                    info.phone = mval
                } else if (mkey === "EMAIL" && info.email.length === 0) {
                    info.email = mval
                }
            }
            return info
        }
        if (!/^BEGIN:VCARD/i.test(payload))
            return info
        var lines = payload.split(/\r?\n/)
        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i]
            var colon = line.indexOf(":")
            if (colon < 0)
                continue
            var key = line.substring(0, colon).toUpperCase()
            var val = line.substring(colon + 1).replace(/\\([;,\\])/g, "$1")
            if (key.indexOf("FN") === 0 && info.name.length === 0)
                info.name = val
            else if (key.indexOf("TEL") === 0 && info.phone.length === 0)
                info.phone = val
            else if (key.indexOf("EMAIL") === 0 && info.email.length === 0)
                info.email = val
        }
        return info
    }

    // Opens the messaging app with the number and body pre-filled, converting
    // the standard SMSTO payload into a body-carrying "sms:" URI first.
    function openSms() {
        var uri = "sms:" + encodeURIComponent(dialog.sms.number)
        if (dialog.sms.message.length > 0)
            uri += "?body=" + encodeURIComponent(dialog.sms.message)
        Qt.openUrlExternally(uri)
    }

    // Opens the location: the native maps app on mobile (geo: scheme), or a
    // Google Maps web link in the browser on desktop.
    function openMap() {
        if (dialog.isMobile) {
            Qt.openUrlExternally(dialog.content)
            return
        }
        var url
        if (dialog.geo.lat.length > 0 && dialog.geo.lon.length > 0
                && !(parseFloat(dialog.geo.lat) === 0 && parseFloat(dialog.geo.lon) === 0)) {
            url = "https://www.google.com/maps?q=" + dialog.geo.lat + "," + dialog.geo.lon
        } else if (dialog.geo.label.length > 0) {
            url = "https://www.google.com/maps/search/?api=1&query="
                + encodeURIComponent(dialog.geo.label)
        } else {
            url = "https://www.google.com/maps?q=" + dialog.geo.lat + "," + dialog.geo.lon
        }
        Qt.openUrlExternally(url)
    }

    // Adds a contact: via the OS "new contact" screen on Android, or by saving
    // a .vcf file the user can import on desktop.
    function addContact(name, phone, email) {
        if (platformBridge.contactInsertSupported) {
            if (!platformBridge.addContact(name, phone, email))
                hint.flash(qsTr("Couldn't open contacts"))
        } else {
            dialog.pendingName = name
            dialog.pendingPhone = phone
            dialog.pendingEmail = email
            contactSaveDialog.currentFile = contactSaveDialog.currentFolder
                + "/" + (name.length > 0 ? name.replace(/[^\w.-]+/g, "_") : "contact") + ".vcf"
            contactSaveDialog.open()
        }
    }

    readonly property string urlHost: {
        const match = content.match(/^https?:\/\/([^/?#]+)/i)
        return match ? match[1] : ""
    }
    // Human label and glyph per recognised kind, keyed by the kind id.
    readonly property var kindMeta: ({
        "url":       { label: qsTr("Website link"),   glyph: "🔗" },
        "wifi":      { label: qsTr("Wi-Fi network"),  glyph: "📶" },
        "email":     { label: qsTr("Email"),          glyph: "✉️" },
        "tel":       { label: qsTr("Phone number"),   glyph: "📞" },
        "sms":       { label: qsTr("Text message"),   glyph: "💬" },
        "geo":       { label: qsTr("Location"),       glyph: "📍" },
        "vcard":     { label: qsTr("Contact card"),   glyph: "👤" },
        "otp":       { label: qsTr("Authenticator"),  glyph: "🔑" },
        "calendar":  { label: qsTr("Calendar event"), glyph: "📅" },
        "sepa":      { label: qsTr("Bank transfer"),  glyph: "🏦" },
        "whatsapp":  { label: qsTr("WhatsApp"),       glyph: "💬" },
        "telegram":  { label: qsTr("Telegram"),       glyph: "✈️" },
        "signal":    { label: qsTr("Signal"),         glyph: "🔒" },
        "facetime":  { label: qsTr("FaceTime"),       glyph: "📹" },
        "messenger": { label: qsTr("Messenger"),      glyph: "💬" },
        "bitcoin":   { label: qsTr("Bitcoin"),        glyph: "₿" },
        "ethereum":  { label: qsTr("Ethereum"),       glyph: "Ξ" },
        "upi":       { label: qsTr("UPI payment"),    glyph: "💳" },
        "paypal":    { label: qsTr("PayPal"),         glyph: "💳" },
        "store":     { label: qsTr("App store"),      glyph: "🛒" },
        "text":      { label: qsTr("Plain text"),     glyph: "📄" }
    })
    readonly property string kindLabel: kindMeta[kind].label
    readonly property string kindGlyph: kindMeta[kind].glyph

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

    // Desktop-only: saves the pending contact as a .vcf file for import.
    FileDialog {
        id: contactSaveDialog
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("vCard (*.vcf)")]
        defaultSuffix: "vcf"
        onAccepted: {
            var card = qrGenerator.vcardPayload(dialog.pendingName, "",
                                                dialog.pendingPhone, dialog.pendingEmail, "")
            if (fileExporter.saveTextFile(selectedFile, card))
                hint.flash(qsTr("Contact saved"))
            else
                hint.flash(qsTr("Couldn't save contact"))
        }
    }

    // Desktop-only: saves the scanned iCalendar payload as a .ics file.
    FileDialog {
        id: calendarSaveDialog
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("iCalendar (*.ics)")]
        defaultSuffix: "ics"
        onAccepted: {
            if (fileExporter.saveTextFile(selectedFile, dialog.content))
                hint.flash(qsTr("Calendar event saved"))
            else
                hint.flash(qsTr("Couldn't save event"))
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

            // Structured view for an email: recipient, subject and message.
            ColumnLayout {
                visible: dialog.isEmail
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: qsTr("To")
                    color: dialog.mutedColor
                    font.pixelSize: 11
                }
                Label {
                    Layout.fillWidth: true
                    text: dialog.emailData.address
                    color: Material.foreground
                    font.pixelSize: 16
                    font.bold: true
                    wrapMode: Text.WrapAnywhere
                }
                Label {
                    visible: dialog.emailData.subject.length > 0
                    Layout.topMargin: 6
                    text: qsTr("Subject")
                    color: dialog.mutedColor
                    font.pixelSize: 11
                }
                Label {
                    visible: dialog.emailData.subject.length > 0
                    Layout.fillWidth: true
                    text: dialog.emailData.subject
                    color: Material.foreground
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
                Label {
                    visible: dialog.emailData.body.length > 0
                    Layout.topMargin: 6
                    text: qsTr("Message")
                    color: dialog.mutedColor
                    font.pixelSize: 11
                }
                Label {
                    visible: dialog.emailData.body.length > 0
                    Layout.fillWidth: true
                    text: dialog.emailData.body
                    color: Material.foreground
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                }
            }

            // Structured view for a two-factor code: account, issuer and type.
            ColumnLayout {
                visible: dialog.isOtp
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: qsTr("Account")
                    color: dialog.mutedColor
                    font.pixelSize: 11
                }
                Label {
                    Layout.fillWidth: true
                    text: dialog.otp.account
                    color: Material.foreground
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    visible: dialog.otp.issuer.length > 0
                    Layout.topMargin: 6
                    text: qsTr("Issuer")
                    color: dialog.mutedColor
                    font.pixelSize: 11
                }
                Label {
                    visible: dialog.otp.issuer.length > 0
                    Layout.fillWidth: true
                    text: dialog.otp.issuer
                    color: Material.foreground
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
                Label {
                    Layout.topMargin: 6
                    text: {
                        var parts = []
                        if (dialog.otp.type.length > 0)
                            parts.push(dialog.otp.type.toUpperCase())
                        if (dialog.otp.algorithm.length > 0)
                            parts.push(dialog.otp.algorithm)
                        if (dialog.otp.digits.length > 0)
                            parts.push(dialog.otp.digits + " " + qsTr("digits"))
                        if (dialog.otp.period.length > 0)
                            parts.push(dialog.otp.period + "s")
                        return parts.join(" \u00B7 ")
                    }
                    color: dialog.mutedColor
                    font.pixelSize: 12
                }
            }

            Rectangle {
                visible: !dialog.isWifi && !dialog.isEmail && !dialog.isOtp
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Type-specific quick actions for the recognised content type.
                // The row's visibility must depend on the data (not on the
                // children's `visible`), because QML propagates `visible` from
                // parent to child — deriving it from children would deadlock.
                RowLayout {
                    id: actionRow
                    Layout.fillWidth: true
                    spacing: 8
                    visible: dialog.isEmail || dialog.isSms || dialog.isGeo
                             || dialog.isTel || dialog.isVCard || dialog.isOtp
                             || dialog.isCalendar || dialog.isOpenable
                             || (dialog.isWifi && platformBridge.wifiConnectSupported)

                    Button {
                        id: emailBtn
                        visible: dialog.isEmail
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: qsTr("Send email")
                        Accessible.name: text
                        onClicked: {
                            var d = dialog.emailData
                            if (!platformBridge.composeEmail(d.address, d.subject, d.body))
                                Qt.openUrlExternally(dialog.buildMailto(d))
                        }
                    }
                    Button {
                        id: smsBtn
                        visible: dialog.isSms
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: qsTr("Send message")
                        Accessible.name: text
                        onClicked: dialog.openSms()
                    }
                    Button {
                        id: mapBtn
                        visible: dialog.isGeo
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: qsTr("Open in Maps")
                        Accessible.name: text
                        onClicked: dialog.openMap()
                    }
                    Button {
                        id: dialBtn
                        visible: dialog.isTel || (dialog.isVCard && dialog.vcard.phone.length > 0)
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: qsTr("Dial")
                        Accessible.name: text
                        onClicked: Qt.openUrlExternally(
                            "tel:" + (dialog.isTel ? dialog.telNumber : dialog.vcard.phone))
                    }
                    Button {
                        id: contactBtn
                        visible: dialog.isTel || dialog.isVCard
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: qsTr("Add contact")
                        Accessible.name: text
                        onClicked: dialog.addContact(
                            dialog.isVCard ? dialog.vcard.name : "",
                            dialog.isVCard ? dialog.vcard.phone : dialog.telNumber,
                            dialog.isVCard ? dialog.vcard.email : "")
                    }
                    Button {
                        id: openBtn
                        visible: dialog.isOpenable
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: dialog.openLabel
                        Accessible.name: text
                        onClicked: {
                            if (!Qt.openUrlExternally(dialog.content))
                                hint.flash(qsTr("No app found to open this"))
                        }
                    }
                    Button {
                        id: wifiBtn
                        visible: dialog.isWifi && platformBridge.wifiConnectSupported
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: qsTr("Connect")
                        Accessible.name: text
                        onClicked: {
                            var ok = platformBridge.connectToWifi(
                                dialog.wifi.ssid, dialog.wifi.password,
                                dialog.wifi.security, dialog.wifi.hidden)
                            if (!ok)
                                hint.flash(qsTr("Couldn't start Wi-Fi connection"))
                        }
                    }
                    Button {
                        id: otpBtn
                        visible: dialog.isOtp
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: qsTr("Add to authenticator")
                        Accessible.name: text
                        onClicked: {
                            if (!Qt.openUrlExternally(dialog.content))
                                hint.flash(qsTr("No authenticator app found"))
                        }
                    }
                    Button {
                        id: calendarBtn
                        visible: dialog.isCalendar
                        Material.background: dialog.primaryColor
                        Material.foreground: dialog.primaryTextColor
                        text: qsTr("Add to calendar")
                        Accessible.name: text
                        onClicked: {
                            var c = dialog.calendar
                            if (platformBridge.calendarInsertSupported) {
                                if (!platformBridge.addCalendarEvent(c.title, c.description,
                                                                     c.location, c.start, c.end))
                                    hint.flash(qsTr("Couldn't open calendar"))
                            } else {
                                calendarSaveDialog.currentFile =
                                    calendarSaveDialog.currentFolder + "/event.ics"
                                calendarSaveDialog.open()
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
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
                }
            }
        }
    }
}
