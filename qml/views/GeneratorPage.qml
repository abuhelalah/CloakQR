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
    property color canvasColor: "#F3F7F5"
    property color primaryColor: "#086C5C"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#5D6F69"

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

    // Location input methods offered for the geo type.
    readonly property int geoModeCoords: 0
    readonly property int geoModeAddress: 1

    property string currentPayload: ""
    property var capacity: ({ fits: false, version: -1, maxBytes: 0, usedBytes: 0 })
    property bool moreTypesShown: false
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

    // Resets every input field for the current content type.
    function clearFields() {
        fieldText.clear()
        fieldSubject.clear()
        fieldBody.clear()
        fieldContactName.clear()
        fieldCountryCode.clear()
        fieldPhoneNumber.clear()
        fieldSmsCountryCode.clear()
        fieldSmsNumber.clear()
        fieldSsid.clear()
        fieldPassword.clear()
        fieldLat.clear()
        fieldLon.clear()
        fieldStreet.clear()
        fieldBuilding.clear()
        fieldPostal.clear()
        fieldCity.clear()
        fieldCountry.clear()
        page.refresh()
    }

    function buildPayload() {
        switch (typeSelector.currentIndex) {
        case typeText:  return qrGenerator.textPayload(fieldText.text)
        case typeUrl:   return qrGenerator.urlPayload(fieldText.text)
        case typeEmail: return qrGenerator.emailPayload(fieldText.text, fieldSubject.text, fieldBody.text)
        case typePhone: {
            var pnum = page.combinedNumber(fieldCountryCode.text, fieldPhoneNumber.text)
            // A name turns the code into a contact card so scanners can add it;
            // without a name a plain "tel:" that dials directly is generated.
            if (fieldContactName.text.trim().length > 0)
                return qrGenerator.vcardPayload(fieldContactName.text, "", pnum, "", "")
            return qrGenerator.phonePayload(pnum)
        }
        case typeSms:   return qrGenerator.smsPayload(
                            page.combinedNumber(fieldSmsCountryCode.text, fieldSmsNumber.text),
                            fieldBody.text)
        case typeWifi:  return qrGenerator.wifiPayload(fieldSsid.text, fieldPassword.text,
                                                       wifiAuth.currentValue, wifiHidden.checked)
        case typeGeo: {
            if (geoModeSelector.currentIndex === page.geoModeAddress) {
                var addr = page.composedAddress()
                return addr.length > 0 ? qrGenerator.geoPayload(0, 0, addr) : ""
            }
            return qrGenerator.geoPayload(parseFloat(fieldLat.text || "0"),
                                          parseFloat(fieldLon.text || "0"), "")
        }
        }
        return ""
    }

    // Editing any input clears the previously generated QR. Generation only
    // runs when the user taps the "Generate" button — there is no live preview.
    function refresh() {
        qrImage.source = ""
        page.currentPayload = ""
        page.capacity = ({ fits: false, version: -1, maxBytes: 0, usedBytes: 0 })
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

        page.capacity = qrGenerator.capacityInfo(payload, eccSelector.currentIndex)
        if (!page.capacity.fits) {
            qrImage.source = ""
            return
        }

        qrImage.source = "image://qrcode/" + encodeURIComponent(payload)
                         + "?e=" + eccSelector.currentIndex
                         + "&f=" + page.colorHex(fgColor.color)
                         + "&b=" + page.colorHex(bgColor.color)
    }

    function savePngTo(url) {
        qrGenerator.requestSavePng(page.currentPayload, eccSelector.currentIndex,
                                   2048, fgColor.color, bgColor.color, url)
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
        case typePhone: {
            if (fieldContactName.text.trim().length > 0)
                return makeBaseName("contact", sanitizeComponent(fieldContactName.text, true))
            if (fieldPhoneNumber.text.trim().length > 0)
                return makeBaseName("contact", sanitizeComponent(fieldPhoneNumber.text, true))
            return "contact_" + filenameTimestamp()
        }
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
            if (geoModeSelector.currentIndex === page.geoModeAddress) {
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

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        GridLayout {
            width: Math.min(page.width, page.twoColumn ? 1160 : 600)
            x: Math.max(0, (page.width - width) / 2)
            columns: page.twoColumn ? 2 : 1
            columnSpacing: 28
            rowSpacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                Layout.row: 0
                Layout.column: 0
                Layout.rowSpan: page.twoColumn ? 3 : 1
                Layout.preferredWidth: page.twoColumn ? 540 : -1
                Layout.leftMargin: page.twoColumn ? 28 : 20
                Layout.rightMargin: page.twoColumn ? 0 : 20
                Layout.topMargin: page.twoColumn ? 28 : 20
                Layout.bottomMargin: page.twoColumn ? 28 : 0
                spacing: 12

                // ===== SELECT TYPE =====
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: qsTr("Select type")
                    font.pixelSize: 11
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.2
                    color: page.mutedColor
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: page.twoColumn ? 6 : 3
                    columnSpacing: 8
                    rowSpacing: 8
                    uniformCellWidths: true
                    uniformCellHeights: true

                    Repeater {
                        model: [
                            { type: page.typeUrl,   label: qsTr("URL"),      icon: "qrc:/icons/url.svg",      primary: true },
                            { type: page.typeText,  label: qsTr("Text"),     icon: "qrc:/icons/text.svg",     primary: true },
                            { type: page.typeWifi,  label: qsTr("Wi-Fi"),    icon: "qrc:/icons/wifi.svg",     primary: true },
                            { type: page.typeEmail, label: qsTr("Email"),    icon: "qrc:/icons/email.svg",    primary: true },
                            { type: page.typePhone, label: qsTr("Phone"),    icon: "qrc:/icons/phone.svg",    primary: true },
                            { type: page.typeGeo,   label: qsTr("Location"), icon: "qrc:/icons/location.svg", primary: true },
                            { type: page.typeSms,   label: qsTr("SMS"),      icon: "qrc:/icons/sms.svg",      primary: false }
                        ]

                        delegate: Button {
                            id: typeChip
                            required property var modelData
                            readonly property bool selected: typeSelector.currentIndex === modelData.type
                            visible: modelData.primary || page.moreTypesShown
                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            focusPolicy: Qt.StrongFocus
                            Accessible.name: modelData.label
                            Accessible.role: Accessible.Button
                            onClicked: typeSelector.currentIndex = modelData.type

                            contentItem: ColumnLayout {
                                spacing: 4
                                SvgIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: modelData.icon
                                    color: typeChip.selected ? page.primaryTextColor : Material.foreground
                                    size: 22
                                }
                                Label {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.label
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: typeChip.selected ? page.primaryTextColor : Material.foreground
                                    elide: Text.ElideRight
                                }
                            }
                            background: Rectangle {
                                radius: 10
                                color: typeChip.selected ? page.primaryColor
                                    : Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.10)
                                border.width: 1
                                border.color: typeChip.selected ? page.primaryColor
                                    : Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.22)
                            }
                        }
                    }
                }

                Button {
                    id: moreTypesButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: qsTr("Show more types")
                    onClicked: page.moreTypesShown = !page.moreTypesShown

                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Label {
                            text: page.moreTypesShown ? qsTr("Show less types") : qsTr("Show more types")
                            font.pixelSize: 12
                            font.bold: true
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 0.6
                            color: page.primaryColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        SvgIcon {
                            source: "qrc:/icons/chevron_down.svg"
                            color: page.primaryColor
                            size: 16
                            rotation: page.moreTypesShown ? 180 : 0
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on rotation { NumberAnimation { duration: 150 } }
                        }
                    }
                    background: Rectangle {
                        radius: 8
                        color: "transparent"
                        border.width: 1
                        border.color: page.primaryColor
                    }
                }

                // Hidden state holder; the chips above drive its index.
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
                        { label: qsTr("Location"),  value: "geo" }
                    ]
                    onCurrentIndexChanged: page.refresh()
                }

                // ===== DATA TO ENCODE =====
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    text: qsTr("Data to encode")
                    font.pixelSize: 11
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.2
                    color: page.mutedColor
                }

                // --- Generic single-line field (text/url/email) --------------
                PasteField {
                    id: fieldText
                    Layout.fillWidth: true
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
                    accessibleName: qsTr("Primary content field")
                    onChanged: page.refresh()
                }

                // --- Phone (contact) fields ----------------------------------
                PasteField {
                    id: fieldContactName
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typePhone
                    placeholderText: qsTr("Name (optional)")
                    accessibleName: qsTr("Contact name")
                    onChanged: page.refresh()
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typePhone
                    spacing: 8

                    PasteField {
                        id: fieldCountryCode
                        Layout.preferredWidth: 130
                        placeholderText: qsTr("+1")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        accessibleName: qsTr("Country code")
                        onChanged: page.refresh()
                    }
                    PasteField {
                        id: fieldPhoneNumber
                        Layout.fillWidth: true
                        placeholderText: qsTr("Phone number")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        accessibleName: qsTr("Phone number")
                        onChanged: page.refresh()
                    }
                }

                // --- SMS number fields ---------------------------------------
                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeSms
                    spacing: 8

                    PasteField {
                        id: fieldSmsCountryCode
                        Layout.preferredWidth: 130
                        placeholderText: qsTr("+1")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        accessibleName: qsTr("Country code")
                        onChanged: page.refresh()
                    }
                    PasteField {
                        id: fieldSmsNumber
                        Layout.fillWidth: true
                        placeholderText: qsTr("Recipient number")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        accessibleName: qsTr("Recipient number")
                        onChanged: page.refresh()
                    }
                }

                // --- Email / SMS extras --------------------------------------
                PasteField {
                    id: fieldSubject
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeEmail
                    placeholderText: qsTr("Subject")
                    accessibleName: qsTr("Email subject")
                    onChanged: page.refresh()
                }

                PasteField {
                    id: fieldBody
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeEmail
                             || typeSelector.currentIndex === page.typeSms
                    placeholderText: typeSelector.currentIndex === page.typeSms
                                     ? qsTr("Message") : qsTr("Body")
                    accessibleName: qsTr("Message body")
                    onChanged: page.refresh()
                }

                // --- Wi-Fi fields --------------------------------------------
                PasteField {
                    id: fieldSsid
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeWifi
                    placeholderText: qsTr("Network name (SSID)")
                    accessibleName: qsTr("Wi-Fi network name")
                    onChanged: page.refresh()
                }

                PasteField {
                    id: fieldPassword
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeWifi
                             && wifiAuth.currentValue !== "none"
                    placeholderText: qsTr("Password")
                    echoMode: TextInput.Password
                    accessibleName: qsTr("Wi-Fi password")
                    onChanged: page.refresh()
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeWifi
                    spacing: 12

                    ComboBox {
                        id: wifiAuth
                        Layout.fillWidth: true
                        Accessible.name: qsTr("Wi-Fi security")
                        textRole: "label"
                        valueRole: "value"
                        model: [
                            { label: qsTr("WPA/WPA2"), value: "WPA" },
                            { label: qsTr("WEP"),      value: "WEP" },
                            { label: qsTr("None"),     value: "none" }
                        ]
                        onCurrentIndexChanged: page.refresh()
                    }

                    CheckBox {
                        id: wifiHidden
                        text: qsTr("Hidden")
                        Accessible.name: qsTr("Hidden network")
                        onCheckedChanged: page.refresh()
                    }
                }

                // --- Geo fields ----------------------------------------------
                ComboBox {
                    id: geoModeSelector
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                    Accessible.name: qsTr("Location input method")
                    textRole: "label"
                    valueRole: "value"
                    model: [
                        { label: qsTr("Coordinates"), value: "coords" },
                        { label: qsTr("Address"),     value: "address" }
                    ]
                    onActivated: page.refresh()
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeCoords
                    spacing: 8

                    PasteField {
                        id: fieldLat
                        Layout.fillWidth: true
                        placeholderText: qsTr("Latitude")
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        accessibleName: qsTr("Latitude")
                        onChanged: page.refresh()
                    }
                    PasteField {
                        id: fieldLon
                        Layout.fillWidth: true
                        placeholderText: qsTr("Longitude")
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        accessibleName: qsTr("Longitude")
                        onChanged: page.refresh()
                    }
                }

                PasteField {
                    id: fieldStreet
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeAddress
                    placeholderText: qsTr("Street")
                    accessibleName: qsTr("Street")
                    onChanged: page.refresh()
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeAddress
                    spacing: 8

                    PasteField {
                        id: fieldBuilding
                        Layout.fillWidth: true
                        placeholderText: qsTr("Building number")
                        accessibleName: qsTr("Building number")
                        onChanged: page.refresh()
                    }
                    PasteField {
                        id: fieldPostal
                        Layout.fillWidth: true
                        placeholderText: qsTr("Postal code")
                        accessibleName: qsTr("Postal code")
                        onChanged: page.refresh()
                    }
                }

                PasteField {
                    id: fieldCity
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeAddress
                    placeholderText: qsTr("City")
                    accessibleName: qsTr("City")
                    onChanged: page.refresh()
                }

                PasteField {
                    id: fieldCountry
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeAddress
                    placeholderText: qsTr("Country")
                    accessibleName: qsTr("Country")
                    onChanged: page.refresh()
                }

                // Clears every field for the selected type.
                Button {
                    Layout.alignment: Qt.AlignRight
                    Layout.topMargin: 4
                    flat: true
                    Accessible.name: qsTr("Clear all fields")
                    onClicked: page.clearFields()

                    contentItem: Label {
                        text: qsTr("Clear")
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.6
                        color: page.primaryColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // ===== QR CONFIGURATION =====
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    text: qsTr("QR configuration")
                    font.pixelSize: 11
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.2
                    color: page.mutedColor
                }

                // --- Error correction ----------------------------------------
                Label {
                    text: qsTr("Error correction")
                    font.bold: true
                }

                ComboBox {
                    id: eccSelector
                    Layout.fillWidth: true
                    currentIndex: 1
                    Accessible.name: qsTr("Error correction level")
                    model: [
                        qsTr("L (7%)"),
                        qsTr("M (15%)"),
                        qsTr("Q (25%)"),
                        qsTr("H (30%)")
                    ]
                    onCurrentIndexChanged: page.refresh()
                }

                // --- Colours -------------------------------------------------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        spacing: 4
                        Label { text: qsTr("Foreground") }
                        Rectangle {
                            id: fgColor
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 32
                            radius: 4
                            color: "#000000"
                            border.color: Material.dividerColor
                            border.width: 1
                            TapHandler { onTapped: { fgDialog.selectedColor = fgColor.color; fgDialog.open() } }
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Label { text: qsTr("Background") }
                        Rectangle {
                            id: bgColor
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 32
                            radius: 4
                            color: "#ffffff"
                            border.color: Material.dividerColor
                            border.width: 1
                            TapHandler { onTapped: { bgDialog.selectedColor = bgColor.color; bgDialog.open() } }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // --- Capacity feedback ---------------------------------------
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: page.currentPayload.length > 0
                    color: page.capacity.fits ? Material.foreground : Material.color(Material.Red)
                    text: page.capacity.fits
                          ? qsTr("Version %1 · %2 / %3 bytes")
                              .arg(page.capacity.version)
                              .arg(page.capacity.usedBytes)
                              .arg(page.capacity.maxBytes)
                          : qsTr("Content is too large for the selected error correction level.")
                }

                // --- Generate ------------------------------------------------
                Button {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: qsTr("Generate QR code")
                    onClicked: page.refreshNow()

                    contentItem: Label {
                        text: qsTr("Generate Cloaked QR")
                        font.pixelSize: 14
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.6
                        color: page.primaryTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: page.primaryColor
                    }
                }
            }

            // --- Preview -----------------------------------------------------
            Rectangle {
                Layout.row: page.twoColumn ? 0 : 1
                Layout.column: page.twoColumn ? 1 : 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: page.twoColumn ? 72 : 8
                Layout.preferredWidth: page.twoColumn ? 360 : 280
                Layout.preferredHeight: Layout.preferredWidth
                color: bgColor.color
                radius: 8
                border.color: Material.dividerColor
                border.width: 1
                visible: qrImage.source.toString().length > 0

                Image {
                    id: qrImage
                    anchors.fill: parent
                    anchors.margins: 12
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    Accessible.role: Accessible.Graphic
                    Accessible.name: qsTr("Generated QR code preview")
                }
            }

            RowLayout {
                Layout.row: page.twoColumn ? 1 : 2
                Layout.column: page.twoColumn ? 1 : 0
                Layout.fillWidth: true
                Layout.leftMargin: page.twoColumn ? 0 : 20
                Layout.rightMargin: page.twoColumn ? 28 : 20
                Layout.bottomMargin: 24
                spacing: 10

                Button {
                    id: saveBtn
                    Layout.fillWidth: true
                    text: qsTr("Save")
                    enabled: qrImage.source.toString().length > 0 && page.capacity.fits
                    Material.background: enabled ? page.primaryColor
                        : Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.16)
                    Material.foreground: enabled ? page.primaryTextColor : page.mutedColor
                    Accessible.name: qsTr("Save QR code as PNG")
                    onClicked: {
                        if (Qt.platform.os === "android" || Qt.platform.os === "ios") {
                            saveDialog.currentFile = page.defaultSaveFileUrl()
                            saveDialog.open()
                        } else {
                            savePicker.openAt(page.folderUrl())
                        }
                    }

                    contentItem: Item {
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            SvgIcon {
                                source: "qrc:/icons/download.svg"
                                color: saveBtn.enabled ? page.primaryTextColor : page.mutedColor
                                size: 18
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Label {
                                text: saveBtn.text
                                color: saveBtn.enabled ? page.primaryTextColor : page.mutedColor
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                Button {
                    id: shareBtn
                    property bool showingCopied: false
                    Layout.fillWidth: true
                    text: shareBtn.showingCopied ? qsTr("Copied!") : qsTr("Share")
                    enabled: qrImage.source.toString().length > 0 && page.capacity.fits
                    Material.background: enabled ? page.primaryColor
                        : Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.16)
                    Material.foreground: enabled ? page.primaryTextColor : page.mutedColor
                    Accessible.name: qsTr("Share QR code")
                    onClicked: {
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
                        qrGenerator.requestSavePng(page.currentPayload, eccSelector.currentIndex,
                                                   1024, fgColor.color, bgColor.color,
                                                   dir + "/qr_share.png", page.shareSaveRequest)
                    }

                    contentItem: Item {
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            SvgIcon {
                                source: "qrc:/icons/share.svg"
                                color: shareBtn.enabled ? page.primaryTextColor : page.mutedColor
                                size: 18
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Label {
                                text: shareBtn.text
                                color: shareBtn.enabled ? page.primaryTextColor : page.mutedColor
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }

    ColorDialog {
        id: fgDialog
        onAccepted: { fgColor.color = selectedColor; page.refresh() }
    }

    ColorDialog {
        id: bgDialog
        onAccepted: { bgColor.color = selectedColor; page.refresh() }
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
