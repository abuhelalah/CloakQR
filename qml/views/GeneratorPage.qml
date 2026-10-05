import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtQuick.Layouts

Page {
    id: page
    title: qsTr("Generator")
    property bool wideLayout: false
    // The form+preview side-by-side layout only works when there is genuinely
    // room for a 540px form and a 360px preview. Between the phone/tablet
    // threshold and this width the page falls back to the single-column layout
    // so the Save/Share actions are never squeezed into a tiny gutter.
    readonly property bool twoColumn: page.wideLayout && page.width >= 980
    property color canvasColor: "#F1F5F3"
    property color primaryColor: "#0B6B5E"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#4B5754"
    property color surfaceColor: "#FFFFFF"
    property color containerColor: "#D5EBE4"
    property color containerTextColor: "#053B33"
    property color errorColor: "#B3261E"
    readonly property real sideMargin: page.twoColumn ? 28 : 16
    // The rail layout has no top bar, so the page shows its own title there.
    readonly property bool showTitle: ApplicationWindow.window !== null
                                      && ApplicationWindow.window.railLayout === true

    background: Rectangle {
        color: page.canvasColor
    }

    // Hidden helper used to place the generated payload on the clipboard.
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

    Timer {
        id: previewTimer
        interval: 250
        onTriggered: page.refreshNow()
    }

    Timer {
        id: copyTimer
        interval: 1500
        onTriggered: shareBtn.showingCopied = false
    }

    // Content type indices match the ComboBox model order below.
    readonly property int typeText: 0
    readonly property int typeUrl: 1
    readonly property int typeEmail: 2
    readonly property int typePhone: 3
    readonly property int typeSms: 4
    readonly property int typeWifi: 5
    readonly property int typeGeo: 6
    readonly property int typeWhatsapp: 7
    readonly property int typeContact: 8

    // Location input methods offered for the geo type.
    readonly property int geoModeCoords: 0
    readonly property int geoModeAddress: 1

    property string currentPayload: ""
    property var capacity: ({ fits: false, version: -1, maxBytes: 0, usedBytes: 0 })
    property bool moreTypesShown: false
    // QR appearance: error-correction index (L, M, Q, H) and module colours.
    property int eccLevel: 1
    property color fgColor: "#000000"
    property color bgColor: "#FFFFFF"
    property string wifiAuthValue: "WPA"
    property int geoMode: geoModeCoords
    readonly property bool hasQr: qrImage.source.toString().length > 0
    // Request id of the in-flight async share save (0 = none). When the PNG is
    // written it is handed to the platform share sheet.
    property int shareSaveRequest: 0

    // Strips the leading '#' from a QML colour so it can be passed as a query
    // value (the '#' would otherwise be treated as a URL fragment).
    function colorHex(c) {
        const s = c.toString()
        return s.charAt(0) === "#" ? s.substring(1) : s
    }

    // Joins an optional country code with a subscriber number, ensuring the
    // result carries a leading '+' when a country code is supplied.
    function combinedNumber(cc, num) {
        var c = (cc || "").toString().trim()
        var n = (num || "").toString().trim()
        if (c.length > 0 && c.charAt(0) !== "+")
            c = "+" + c
        return c + n
    }

    // Joins the structured address fields into a single, human-readable line
    // that scanners resolve as a place query.
    function composedAddress() {
        var parts = []
        var line1 = (fieldStreet.text.trim() + " " + fieldBuilding.text.trim()).trim()
        if (line1.length > 0)
            parts.push(line1)
        var line2 = (fieldPostal.text.trim() + " " + fieldCity.text.trim()).trim()
        if (line2.length > 0)
            parts.push(line2)
        if (fieldCountry.text.trim().length > 0)
            parts.push(fieldCountry.text.trim())
        return parts.join(", ")
    }

    // True when the selected type has nothing worth encoding yet, so the live
    // preview stays empty instead of showing e.g. "geo:0,0" or a blank Wi-Fi.
    function inputEmpty() {
        const blank = (f) => f.text.trim().length === 0
        switch (typeSelector.currentIndex) {
        case typeText:
        case typeUrl:
        case typeEmail: return blank(fieldText)
        case typePhone: return blank(fieldPhoneNumber)
        case typeSms:   return blank(fieldSmsNumber) && blank(fieldBody)
        case typeWhatsapp: return blank(fieldSmsNumber)
        case typeContact:  return blank(fieldContactName) && blank(fieldPhoneNumber)
                                  && blank(fieldContactEmail)
        case typeWifi:  return blank(fieldSsid)
        case typeGeo:
            return page.geoMode === page.geoModeAddress
                   ? page.composedAddress().length === 0
                   : (blank(fieldLat) || blank(fieldLon))
        }
        return true
    }

    // History type for the current payload, matching the scanner's categories.
    function historyType() {
        switch (typeSelector.currentIndex) {
        case typeUrl:   return "url"
        case typeEmail: return "email"
        case typePhone: return "tel"
        case typeSms:   return "sms"
        case typeWhatsapp: return "whatsapp"
        case typeContact:  return "vcard"
        case typeWifi:  return "wifi"
        case typeGeo:   return "geo"
        }
        return "text"
    }

    // Records a created code once it is saved or shared, under the same rules
    // as scans: only with history on, and Wi-Fi codes skipped when excluded.
    property string lastRecordedPayload: ""
    function recordInHistory() {
        const payload = page.currentPayload
        if (payload.length === 0 || payload === page.lastRecordedPayload)
            return
        if (!appSettings.historyEnabled)
            return
        if (appSettings.historyExcludeWifiPassword && payload.startsWith("WIFI:"))
            return
        scanHistory.addEntry(payload, page.historyType(), "generated")
        page.lastRecordedPayload = payload
    }

    function buildPayload() {
        if (page.inputEmpty())
            return ""
        switch (typeSelector.currentIndex) {
        case typeText:  return qrGenerator.textPayload(fieldText.text)
        case typeUrl:   return qrGenerator.urlPayload(fieldText.text)
        case typeEmail: return qrGenerator.emailPayload(fieldText.text, fieldSubject.text, fieldBody.text)
        case typePhone: return qrGenerator.phonePayload(
                            page.combinedNumber(fieldCountryCode.text, fieldPhoneNumber.text))
        case typeContact: return qrGenerator.vcardPayload(
                              fieldContactName.text.trim(), fieldContactOrg.text.trim(),
                              page.combinedNumber(fieldCountryCode.text, fieldPhoneNumber.text),
                              fieldContactEmail.text.trim(), fieldContactUrl.text.trim())
        case typeWhatsapp: return qrGenerator.whatsappPayload(
                               page.combinedNumber(fieldSmsCountryCode.text, fieldSmsNumber.text),
                               fieldBody.text)
        case typeSms:   return qrGenerator.smsPayload(
                            page.combinedNumber(fieldSmsCountryCode.text, fieldSmsNumber.text),
                            fieldBody.text)
        case typeWifi:  return qrGenerator.wifiPayload(fieldSsid.text, fieldPassword.text,
                                                       page.wifiAuthValue, wifiHidden.checked)
        case typeGeo: {
            if (page.geoMode === page.geoModeAddress) {
                var addr = page.composedAddress()
                return addr.length > 0 ? qrGenerator.geoPayload(0, 0, addr) : ""
            }
            return qrGenerator.geoPayload(parseFloat(fieldLat.text || "0"),
                                          parseFloat(fieldLon.text || "0"), "")
        }
        }
        return ""
    }

    // Live preview: any edit schedules a re-encode once typing pauses, so the
    // QR is not rebuilt on every keystroke.
    function refresh() {
        previewTimer.restart()
    }

    // Encodes the payload once for the capacity read-out, then hands the
    // preview to the image provider, which renders it at the Image's size.
    function refreshNow() {
        const payload = buildPayload()
        page.currentPayload = payload

        if (payload.length === 0) {
            qrImage.source = ""
            page.capacity = ({ fits: false, version: -1, maxBytes: 0, usedBytes: 0 })
            return
        }

        page.capacity = qrGenerator.capacityInfo(payload, page.eccLevel)
        if (!page.capacity.fits) {
            qrImage.source = ""
            return
        }

        qrImage.source = "image://qrcode/" + encodeURIComponent(payload)
                         + "?e=" + page.eccLevel
                         + "&f=" + page.colorHex(page.fgColor)
                         + "&b=" + page.colorHex(page.bgColor)
    }

    function savePngTo(url) {
        page.recordInHistory()
        qrGenerator.requestSavePng(page.currentPayload, page.eccLevel,
                                   2048, page.fgColor, page.bgColor, url)
    }

    // Builds a valid file: URL from a plain filesystem path. On Windows a drive
    // path ("C:/Users/…") needs the triple-slash form ("file:///C:/Users/…"),
    // otherwise the drive letter is mis-parsed as the URL host.
    function folderUrl() {
        var p = appSettings.defaultSaveDirectory
        if (!p || p.length === 0)
            return ""
        if (p.indexOf("file:") === 0)
            return p
        var s = p.replace(/\\/g, "/")
        return s.charAt(0) === "/" ? "file://" + s : "file:///" + s
    }

    // --- Save filename helpers -----------------------------------------

    function pad2(n) {
        return n < 10 ? "0" + n : "" + n
    }

    // Compact timestamp "YYYYMMDD_HHMMSS" used when no usable slug exists.
    function filenameTimestamp() {
        const d = new Date()
        return "" + d.getFullYear() + pad2(d.getMonth() + 1) + pad2(d.getDate())
                + "_" + pad2(d.getHours()) + pad2(d.getMinutes()) + pad2(d.getSeconds())
    }

    // Strips control characters and characters illegal on Android/desktop
    // filesystems, collapses whitespace, and lowercases unless preserveCase is
    // set (SSIDs and contact names keep their original case). Non-Latin
    // characters are preserved.
    function sanitizeComponent(raw, preserveCase) {
        var s = String(raw || "")
        s = s.replace(/[\u0000-\u001f\u007f]/g, "")
        s = s.replace(/[\\/:*?"<>|]/g, "")
        s = s.replace(/\s+/g, "")
        if (!preserveCase)
            s = s.toLowerCase()
        s = s.replace(/_+/g, "_")
        s = s.replace(/^_+|_+$/g, "")
        s = s.replace(/\.+$/, "")
        return s
    }

    // First whitespace-separated token of the input.
    function firstWord(raw) {
        const m = (raw || "").trim().match(/\S+/)
        return m ? m[0] : ""
    }

    // Caps "<prefix>_<rest>" at 30 characters, truncating only the variable
    // part (never the type prefix).
    function capName(prefix, rest) {
        const name = prefix + "_" + rest
        if (name.length <= 30)
            return name
        const maxRest = 30 - prefix.length - 1
        return maxRest > 0 ? (prefix + "_" + rest.substring(0, maxRest)) : prefix
    }

    // Final "<prefix>_<slug>" builder; empty slugs fall back to a timestamp.
    function makeBaseName(prefix, rest) {
        return rest.length > 0 ? capName(prefix, rest) : (prefix + "_" + filenameTimestamp())
    }

    // Registrable domain's main label: strips scheme, "www.", path/query, then
    // keeps the first dot-separated label ("example.com" -> "example",
    // "https://www.foo.co.uk/x" -> "foo").
    function domainMainLabel(raw) {
        var s = (raw || "").trim()
        s = s.replace(/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//, "")
        s = s.replace(/^www\./i, "")
        s = s.split(/[/?#]/)[0]
        const parts = s.split(".")
        return parts.length > 0 ? parts[0] : s
    }

    // Local part of an address, or the first word when there is no '@'.
    function emailLocalPart(raw) {
        const s = (raw || "").trim()
        const at = s.indexOf("@")
        return at > 0 ? s.substring(0, at) : firstWord(s)
    }

    // Non-empty, sanitised base filename (no extension) for the selected type.
    function suggestedBaseName() {
        switch (typeSelector.currentIndex) {
        case typeText:
            return makeBaseName("text", sanitizeComponent(firstWord(fieldText.text)))
        case typeUrl:
            return makeBaseName("url", sanitizeComponent(domainMainLabel(fieldText.text)))
        case typeEmail: {
            const local = sanitizeComponent(emailLocalPart(fieldText.text))
            const extra = sanitizeComponent(firstWord(
                fieldSubject.text.length > 0 ? fieldSubject.text : fieldBody.text))
            if (local.length > 0 && extra.length > 0)
                return capName("email", local + "_" + extra)
            if (local.length > 0)
                return makeBaseName("email", local)
            return makeBaseName("email", extra)
        }
        case typeWifi:
            return makeBaseName("wifi", sanitizeComponent(fieldSsid.text, true))
        case typePhone:
            return makeBaseName("phone", sanitizeComponent(fieldPhoneNumber.text, true))
        case typeContact: {
            if (fieldContactName.text.trim().length > 0)
                return makeBaseName("contact", sanitizeComponent(fieldContactName.text, true))
            return makeBaseName("contact", sanitizeComponent(fieldPhoneNumber.text, true))
        }
        case typeWhatsapp:
            return makeBaseName("whatsapp", sanitizeComponent(fieldSmsNumber.text, true))
        case typeSms: {
            const num = sanitizeComponent(fieldSmsNumber.text, true)
            const msg = sanitizeComponent(firstWord(fieldBody.text))
            if (num.length > 0 && msg.length > 0)
                return capName("sms", num + "_" + msg)
            if (num.length > 0)
                return makeBaseName("sms", num)
            if (msg.length > 0)
                return makeBaseName("sms", msg)
            return "sms_" + filenameTimestamp()
        }
        case typeGeo:
            if (page.geoMode === page.geoModeAddress) {
                const street = sanitizeComponent(fieldStreet.text)
                const building = sanitizeComponent(fieldBuilding.text)
                if (street.length > 0 && building.length > 0)
                    return capName("gps", street + "_" + building)
                if (street.length > 0)
                    return makeBaseName("gps", street)
                if (building.length > 0)
                    return makeBaseName("gps", building)
                return "gps_" + filenameTimestamp()
            }
            const lat = sanitizeComponent(fieldLat.text)
            const lon = sanitizeComponent(fieldLon.text)
            if (lat.length > 0 && lon.length > 0)
                return capName("gps", lat + "_" + lon)
            return "gps_" + filenameTimestamp()
        }
        return "qr_" + filenameTimestamp()
    }

    // Full file:// URL (with .png) pre-filled into the native mobile picker.
    function defaultSaveFileUrl() {
        const dir = page.folderUrl()
        if (!dir || dir.length === 0)
            return ""
        var base = dir
        if (!base.endsWith("/"))
            base += "/"
        return base + encodeURIComponent(page.suggestedBaseName() + ".png")
    }

    // --- Building blocks -----------------------------------------------------
    component SectionHeader: Label {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        font.pixelSize: 12
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
        color: page.mutedColor
    }

    component Field: PasteField {
        Layout.fillWidth: true
        fillColor: page.surfaceColor
        mutedColor: page.mutedColor
        onChanged: page.refresh()
    }

    // A row of colour swatches plus a "custom" swatch that opens a picker.
    component SwatchRow: RowLayout {
        id: swatchRow
        property var presets: []
        property color current
        signal picked(color value)
        signal customRequested()
        readonly property bool isCustom: {
            for (var i = 0; i < presets.length; ++i)
                if (Qt.colorEqual(presets[i], current))
                    return false
            return true
        }
        spacing: 8

        Repeater {
            model: swatchRow.presets.concat(["custom"])
            delegate: AbstractButton {
                id: swatch
                required property var modelData
                readonly property bool custom: modelData === "custom"
                readonly property bool selected: custom ? swatchRow.isCustom
                                                        : Qt.colorEqual(modelData, swatchRow.current)
                implicitWidth: 52
                implicitHeight: 52
                checkable: true
                checked: selected
                Accessible.role: Accessible.RadioButton
                Accessible.name: custom ? qsTr("Custom colour") : modelData
                onClicked: custom ? swatchRow.customRequested() : swatchRow.picked(modelData)

                // Selection ring with a 2px gap, as in the design.
                background: Rectangle {
                    radius: 16
                    color: "transparent"
                    border.width: swatch.selected ? 2 : 0
                    border.color: page.primaryColor
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 12
                        color: swatch.custom ? (swatchRow.isCustom ? swatchRow.current : page.surfaceColor)
                                             : swatch.modelData
                        border.width: 1
                        border.color: Material.theme === Material.Dark ? Qt.rgba(1, 1, 1, 0.3)
                                                                       : Qt.rgba(0, 0, 0, 0.2)
                        SvgIcon {
                            anchors.centerIn: parent
                            visible: swatch.custom && !swatchRow.isCustom
                            source: "qrc:/icons/nav_create.svg"
                            color: page.mutedColor
                            size: 20
                        }
                    }
                }
                contentItem: Item {}
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        GridLayout {
            width: Math.min(page.width, page.twoColumn ? 1160 : 600)
            x: Math.max(0, (page.width - width) / 2)
            columns: page.twoColumn ? 2 : 1
            columnSpacing: 24
            rowSpacing: 24

            // ===== TYPE + CONTENT =====
            ColumnLayout {
                Layout.row: 0
                Layout.column: 0
                Layout.fillWidth: true
                Layout.preferredWidth: page.twoColumn ? 540 : -1
                Layout.leftMargin: page.sideMargin
                Layout.rightMargin: page.twoColumn ? 0 : page.sideMargin
                Layout.topMargin: page.twoColumn ? 28 : 20
                spacing: 12

                Label {
                    visible: page.showTitle
                    Layout.bottomMargin: 4
                    text: qsTr("Create QR")
                    font.pixelSize: Math.round(28 * appSettings.fontScale)
                    font.bold: true
                }

                SectionHeader { text: qsTr("Type") }

                GridLayout {
                    Layout.fillWidth: true
                    columns: page.twoColumn ? 4 : 3
                    columnSpacing: 10
                    rowSpacing: 10
                    uniformCellWidths: true

                    Repeater {
                        model: [
                            { type: page.typeUrl,   label: qsTr("URL"),      icon: "qrc:/icons/url.svg",      primary: true },
                            { type: page.typeText,  label: qsTr("Text"),     icon: "qrc:/icons/text.svg",     primary: true },
                            { type: page.typeWifi,  label: qsTr("Wi-Fi"),    icon: "qrc:/icons/wifi.svg",     primary: true },
                            { type: page.typeEmail, label: qsTr("Email"),    icon: "qrc:/icons/email.svg",    primary: true },
                            { type: page.typePhone, label: qsTr("Phone"),    icon: "qrc:/icons/phone.svg",    primary: true },
                            { type: page.typeGeo,   label: qsTr("Location"), icon: "qrc:/icons/location.svg", primary: true },
                            { type: page.typeSms,   label: qsTr("SMS"),      icon: "qrc:/icons/sms.svg",      primary: false },
                            { type: page.typeWhatsapp, label: qsTr("WhatsApp"), icon: "qrc:/icons/chat.svg",   primary: false },
                            { type: page.typeContact,  label: qsTr("Contact"),  icon: "qrc:/icons/contact.svg", primary: false }
                        ]

                        delegate: AbstractButton {
                            id: typeTile
                            required property var modelData
                            readonly property bool selected: typeSelector.currentIndex === modelData.type
                            // Tablets have room for every type; phones fold the rest away.
                            visible: modelData.primary || page.moreTypesShown || page.twoColumn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            checkable: true
                            checked: selected
                            focusPolicy: Qt.StrongFocus
                            Accessible.name: modelData.label
                            Accessible.role: Accessible.RadioButton
                            onClicked: typeSelector.currentIndex = modelData.type

                            contentItem: ColumnLayout {
                                spacing: 6
                                Item { Layout.fillHeight: true }
                                SvgIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: typeTile.modelData.icon
                                    color: typeTile.selected ? page.primaryTextColor : Material.foreground
                                    size: 22
                                }
                                Label {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: typeTile.modelData.label
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    color: typeTile.selected ? page.primaryTextColor : Material.foreground
                                    elide: Text.ElideRight
                                }
                                Item { Layout.fillHeight: true }
                            }
                            background: Rectangle {
                                radius: 16
                                color: typeTile.selected ? page.primaryColor
                                     : typeTile.down ? page.containerColor : page.surfaceColor
                                border.width: 1
                                border.color: typeTile.selected ? page.primaryColor
                                    : Material.theme === Material.Dark ? Qt.rgba(1, 1, 1, 0.12) : "#E3E8E6"
                            }
                        }
                    }
                }

                Button {
                    id: moreTypesButton
                    visible: !page.twoColumn
                    flat: true
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: text
                    text: page.moreTypesShown ? qsTr("Fewer types") : qsTr("More types")
                    onClicked: page.moreTypesShown = !page.moreTypesShown
                    contentItem: RowLayout {
                        spacing: 6
                        Label {
                            text: moreTypesButton.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: page.primaryColor
                        }
                        SvgIcon {
                            source: "qrc:/icons/chevron_down.svg"
                            color: page.primaryColor
                            size: 18
                            rotation: page.moreTypesShown ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                // Hidden state holder; the tiles above drive its index.
                ComboBox {
                    id: typeSelector
                    visible: false
                    Accessible.name: qsTr("Content type selector")
                    textRole: "label"
                    valueRole: "value"
                    model: [
                        { label: qsTr("Text"),      value: "text" },
                        { label: qsTr("URL"),       value: "url" },
                        { label: qsTr("Email"),     value: "email" },
                        { label: qsTr("Phone"),     value: "phone" },
                        { label: qsTr("SMS"),       value: "sms" },
                        { label: qsTr("Wi-Fi"),     value: "wifi" },
                        { label: qsTr("Location"),  value: "geo" },
                        { label: qsTr("WhatsApp"),  value: "whatsapp" },
                        { label: qsTr("Contact"),   value: "contact" }
                    ]
                    onCurrentIndexChanged: page.refresh()
                }

                SectionHeader {
                    Layout.topMargin: 12
                    text: qsTr("Content")
                }

                // --- Generic single-line field (text/url/email) --------------
                Field {
                    id: fieldText
                    visible: typeSelector.currentIndex === page.typeText
                             || typeSelector.currentIndex === page.typeUrl
                             || typeSelector.currentIndex === page.typeEmail
                    placeholderText: {
                        switch (typeSelector.currentIndex) {
                        case page.typeUrl:   return qsTr("https://example.com")
                        case page.typeEmail: return qsTr("name@example.com")
                        default:             return qsTr("Enter text")
                        }
                    }
                    accessibleName: {
                        switch (typeSelector.currentIndex) {
                        case page.typeUrl:   return qsTr("Website address")
                        case page.typeEmail: return qsTr("Email address")
                        default:             return qsTr("Text")
                        }
                    }
                }

                // --- Contact / phone fields ----------------------------------
                Field {
                    id: fieldContactName
                    visible: typeSelector.currentIndex === page.typeContact
                    accessibleName: qsTr("Contact name")
                }

                Field {
                    id: fieldContactOrg
                    visible: typeSelector.currentIndex === page.typeContact
                    placeholderText: qsTr("Optional")
                    accessibleName: qsTr("Organization")
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typePhone
                             || typeSelector.currentIndex === page.typeContact
                    spacing: 8

                    Field {
                        id: fieldCountryCode
                        Layout.fillWidth: false
                        Layout.preferredWidth: 110
                        showActions: false
                        placeholderText: qsTr("+1")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        accessibleName: qsTr("Country code")
                    }
                    Field {
                        id: fieldPhoneNumber
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        accessibleName: qsTr("Phone number")
                    }
                }

                Field {
                    id: fieldContactEmail
                    visible: typeSelector.currentIndex === page.typeContact
                    placeholderText: qsTr("name@example.com")
                    inputMethodHints: Qt.ImhEmailCharactersOnly
                    accessibleName: qsTr("Email address")
                }

                Field {
                    id: fieldContactUrl
                    visible: typeSelector.currentIndex === page.typeContact
                    placeholderText: qsTr("Optional")
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    accessibleName: qsTr("Website")
                }

                // --- SMS / WhatsApp number fields ----------------------------
                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeSms
                             || typeSelector.currentIndex === page.typeWhatsapp
                    spacing: 8

                    Field {
                        id: fieldSmsCountryCode
                        Layout.fillWidth: false
                        Layout.preferredWidth: 110
                        showActions: false
                        placeholderText: qsTr("+1")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        accessibleName: qsTr("Country code")
                    }
                    Field {
                        id: fieldSmsNumber
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        accessibleName: qsTr("Recipient number")
                    }
                }

                // --- Email / SMS extras --------------------------------------
                Field {
                    id: fieldSubject
                    visible: typeSelector.currentIndex === page.typeEmail
                    accessibleName: qsTr("Email subject")
                }

                Field {
                    id: fieldBody
                    visible: typeSelector.currentIndex === page.typeEmail
                             || typeSelector.currentIndex === page.typeSms
                             || typeSelector.currentIndex === page.typeWhatsapp
                    label: typeSelector.currentIndex === page.typeEmail ? qsTr("Body") : qsTr("Message")
                    placeholderText: typeSelector.currentIndex === page.typeEmail ? "" : qsTr("Optional")
                    accessibleName: qsTr("Message body")
                }

                // --- Wi-Fi fields --------------------------------------------
                Field {
                    id: fieldSsid
                    visible: typeSelector.currentIndex === page.typeWifi
                    placeholderText: qsTr("Network name (SSID)")
                    accessibleName: qsTr("Wi-Fi network name")
                }

                SegmentedControl {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeWifi
                    model: [
                        { key: "WPA",  label: qsTr("WPA/WPA2") },
                        { key: "WEP",  label: qsTr("WEP") },
                        { key: "none", label: qsTr("None") }
                    ]
                    currentKey: page.wifiAuthValue
                    fillColor: page.surfaceColor
                    selectedColor: page.containerColor
                    selectedTextColor: page.containerTextColor
                    textColor: page.mutedColor
                    Accessible.name: qsTr("Wi-Fi security")
                    onActivated: (key) => { page.wifiAuthValue = key; page.refresh() }
                }

                Field {
                    id: fieldPassword
                    visible: typeSelector.currentIndex === page.typeWifi
                             && page.wifiAuthValue !== "none"
                    echoMode: TextInput.Password
                    accessibleName: qsTr("Wi-Fi password")
                }

                Switch {
                    id: wifiHidden
                    visible: typeSelector.currentIndex === page.typeWifi
                    text: qsTr("Hidden")
                    Accessible.name: qsTr("Hidden network")
                    onCheckedChanged: page.refresh()
                }

                // --- Geo fields ----------------------------------------------
                SegmentedControl {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                    model: [
                        { key: "0", label: qsTr("Coordinates") },
                        { key: "1", label: qsTr("Address") }
                    ]
                    currentKey: String(page.geoMode)
                    fillColor: page.surfaceColor
                    selectedColor: page.containerColor
                    selectedTextColor: page.containerTextColor
                    textColor: page.mutedColor
                    Accessible.name: qsTr("Location input method")
                    onActivated: (key) => { page.geoMode = parseInt(key); page.refresh() }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && page.geoMode === page.geoModeCoords
                    spacing: 8

                    Field {
                        id: fieldLat
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        accessibleName: qsTr("Latitude")
                    }
                    Field {
                        id: fieldLon
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        accessibleName: qsTr("Longitude")
                    }
                }

                Field {
                    id: fieldStreet
                    visible: typeSelector.currentIndex === page.typeGeo
                             && page.geoMode === page.geoModeAddress
                    accessibleName: qsTr("Street")
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && page.geoMode === page.geoModeAddress
                    spacing: 8

                    Field {
                        id: fieldBuilding
                        accessibleName: qsTr("Building number")
                    }
                    Field {
                        id: fieldPostal
                        accessibleName: qsTr("Postal code")
                    }
                }

                Field {
                    id: fieldCity
                    visible: typeSelector.currentIndex === page.typeGeo
                             && page.geoMode === page.geoModeAddress
                    accessibleName: qsTr("City")
                }

                Field {
                    id: fieldCountry
                    visible: typeSelector.currentIndex === page.typeGeo
                             && page.geoMode === page.geoModeAddress
                    accessibleName: qsTr("Country")
                }
            }

            // ===== PREVIEW =====
            Rectangle {
                Layout.row: page.twoColumn ? 0 : 1
                Layout.column: page.twoColumn ? 1 : 0
                Layout.rowSpan: page.twoColumn ? 2 : 1
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredWidth: page.twoColumn ? 440 : -1
                Layout.leftMargin: page.twoColumn ? 0 : page.sideMargin
                Layout.rightMargin: page.sideMargin
                Layout.topMargin: page.twoColumn ? (page.showTitle ? 72 : 28) : 0
                radius: 24
                color: page.surfaceColor
                implicitHeight: previewColumn.implicitHeight + 40

                ColumnLayout {
                    id: previewColumn
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    // QR (or a placeholder until there is something to encode).
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: page.twoColumn ? 300 : 220
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: 12
                        color: page.hasQr ? page.bgColor : page.canvasColor

                        Image {
                            id: qrImage
                            anchors.fill: parent
                            anchors.margins: 12
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            Accessible.role: Accessible.Graphic
                            Accessible.name: qsTr("Generated QR code preview")
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 32
                            visible: !page.hasQr
                            spacing: 10
                            SvgIcon {
                                Layout.alignment: Qt.AlignHCenter
                                source: "qrc:/icons/nav_create.svg"
                                color: page.mutedColor
                                size: 32
                            }
                            Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: qsTr("Your QR code will appear here")
                                color: page.mutedColor
                                font.pixelSize: 14
                            }
                        }
                    }

                    // Capacity read-out.
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: page.currentPayload.length > 0
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            visible: page.capacity.fits
                            Label {
                                Layout.fillWidth: true
                                text: qsTr("Version %1 · ECC %2").arg(page.capacity.version)
                                      .arg(["L", "M", "Q", "H"][page.eccLevel])
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Label {
                                text: qsTr("%1 / %2 bytes").arg(page.capacity.usedBytes)
                                      .arg(page.capacity.maxBytes)
                                font.pixelSize: 13
                                color: page.mutedColor
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            visible: page.capacity.fits
                            implicitHeight: 6
                            radius: 3
                            color: Material.theme === Material.Dark ? Qt.rgba(1, 1, 1, 0.12) : "#E3E8E6"
                            Rectangle {
                                height: parent.height
                                radius: 3
                                width: page.capacity.maxBytes > 0
                                       ? parent.width * Math.min(1, page.capacity.usedBytes / page.capacity.maxBytes)
                                       : 0
                                color: page.primaryColor
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            visible: !page.capacity.fits
                            wrapMode: Text.WordWrap
                            color: page.errorColor
                            text: qsTr("Content is too large for the selected error correction level.")
                        }
                    }

                    // Save / Share once a QR exists.
                    RowLayout {
                        Layout.fillWidth: true
                        visible: page.hasQr
                        spacing: 8

                        Button {
                            id: saveBtn
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 48
                            topInset: 0
                            bottomInset: 0
                            text: qsTr("Save")
                            enabled: page.hasQr && page.capacity.fits
                            Accessible.name: qsTr("Save QR code as PNG")
                            onClicked: {
                                if (Qt.platform.os === "android" || Qt.platform.os === "ios") {
                                    saveDialog.currentFile = page.defaultSaveFileUrl()
                                    saveDialog.open()
                                } else {
                                    savePicker.openAt(page.folderUrl())
                                }
                            }
                            background: Rectangle {
                                radius: height / 2
                                color: page.primaryColor
                                opacity: saveBtn.down ? 0.85 : 1
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Item { Layout.fillWidth: true }
                                SvgIcon {
                                    source: "qrc:/icons/download.svg"
                                    color: page.primaryTextColor
                                    size: 18
                                }
                                Label {
                                    text: saveBtn.text
                                    color: page.primaryTextColor
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }

                        Button {
                            id: shareBtn
                            property bool showingCopied: false
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 48
                            topInset: 0
                            bottomInset: 0
                            text: shareBtn.showingCopied ? qsTr("Copied!") : qsTr("Share")
                            enabled: page.hasQr && page.capacity.fits
                            Accessible.name: qsTr("Share QR code")
                            onClicked: {
                                page.recordInHistory()
                                if (Qt.platform.os !== "android") {
                                    // Desktop fallback: put the payload on the clipboard.
                                    clipboardHelper.copyText(page.currentPayload)
                                    shareBtn.showingCopied = true
                                    copyTimer.restart()
                                    return
                                }
                                if (page.shareSaveRequest !== 0)
                                    return
                                const dir = StandardPaths.writableLocation(StandardPaths.AppDataLocation)
                                page.shareSaveRequest = 1
                                qrGenerator.requestSavePng(page.currentPayload, page.eccLevel,
                                                           1024, page.fgColor, page.bgColor,
                                                           dir + "/qr_share.png", page.shareSaveRequest)
                            }
                            background: Rectangle {
                                radius: height / 2
                                color: shareBtn.down ? Qt.darker(page.containerColor, 1.08) : page.containerColor
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Item { Layout.fillWidth: true }
                                SvgIcon {
                                    source: "qrc:/icons/share.svg"
                                    color: page.containerTextColor
                                    size: 18
                                }
                                Label {
                                    text: shareBtn.text
                                    color: page.containerTextColor
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }

            // ===== APPEARANCE =====
            // A card on tablets; a plain section on phones, as in the design.
            Rectangle {
                Layout.row: page.twoColumn ? 1 : 2
                Layout.column: 0
                Layout.fillWidth: true
                Layout.leftMargin: page.sideMargin
                Layout.rightMargin: page.twoColumn ? 0 : page.sideMargin
                Layout.bottomMargin: 28
                radius: 20
                color: page.twoColumn ? page.surfaceColor : "transparent"
                implicitHeight: appearanceColumn.implicitHeight + (page.twoColumn ? 36 : 0)

                ColumnLayout {
                    id: appearanceColumn
                    anchors.fill: parent
                    anchors.margins: page.twoColumn ? 18 : 0
                    spacing: 16

                    SectionHeader { text: qsTr("Appearance") }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label {
                            text: qsTr("Error correction")
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        SegmentedControl {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            model: [
                                { key: "0", label: qsTr("L 7%") },
                                { key: "1", label: qsTr("M 15%") },
                                { key: "2", label: qsTr("Q 25%") },
                                { key: "3", label: qsTr("H 30%") }
                            ]
                            currentKey: String(page.eccLevel)
                            fillColor: page.surfaceColor
                            selectedColor: page.containerColor
                            selectedTextColor: page.containerTextColor
                            textColor: page.mutedColor
                            Accessible.name: qsTr("Error correction level")
                            onActivated: (key) => { page.eccLevel = parseInt(key); page.refresh() }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 24

                        ColumnLayout {
                            spacing: 8
                            Label {
                                text: qsTr("Foreground")
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            SwatchRow {
                                presets: ["#000000", "#0B6B5E", "#0F1B2D"]
                                current: page.fgColor
                                onPicked: (value) => { page.fgColor = value; page.refresh() }
                                onCustomRequested: { fgDialog.selectedColor = page.fgColor; fgDialog.open() }
                            }
                        }
                        ColumnLayout {
                            spacing: 8
                            Label {
                                text: qsTr("Background")
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            SwatchRow {
                                presets: ["#FFFFFF", "#F4F1EA"]
                                current: page.bgColor
                                onPicked: (value) => { page.bgColor = value; page.refresh() }
                                onCustomRequested: { bgDialog.selectedColor = page.bgColor; bgDialog.open() }
                            }
                        }
                    }
                }
            }
        }
    }

    ColorDialog {
        id: fgDialog
        onAccepted: { page.fgColor = selectedColor; page.refresh() }
    }

    ColorDialog {
        id: bgDialog
        onAccepted: { page.bgColor = selectedColor; page.refresh() }
    }

    // When the async share save lands, hand the written PNG to the platform
    // share sheet. Save-to-disk is fire-and-forget and needs no handling here.
    Connections {
        target: qrGenerator
        function onSaveFinished(path, ok, requestId) {
            if (requestId !== 0 && requestId === page.shareSaveRequest) {
                page.shareSaveRequest = 0
                if (ok)
                    platformBridge.shareFile(path)
            }
        }
        function onSaveFailed(path, reason, requestId) {
            if (requestId !== 0 && requestId === page.shareSaveRequest)
                page.shareSaveRequest = 0
        }
    }

    // Mobile uses the platform's native storage picker.
    FileDialog {
        id: saveDialog
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("PNG image (*.png)")]
        defaultSuffix: "png"
        currentFolder: page.folderUrl()
        onAccepted: page.savePngTo(selectedFile)
    }

    // Desktop uses an in-app, Material-themed picker that follows the theme.
    FilePickerDialog {
        id: savePicker
        saveMode: true
        dialogTitle: qsTr("Save as PNG")
        patterns: ["*.png"]
        defaultSuffix: "png"
        suggestedName: page.suggestedBaseName()
        primaryColor: page.primaryColor
        primaryTextColor: page.primaryTextColor
        mutedColor: page.mutedColor
        onAccepted: (file) => page.savePngTo(file)
    }
}
