import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtQuick.Layouts

Page {
    id: page
    title: qsTr("Generator")
    property bool wideLayout: false
    property color canvasColor: "#F3F7F5"
    property color primaryColor: "#086C5C"
    property color primaryTextColor: "#FFFFFF"
    property color mutedColor: "#5D6F69"

    background: Rectangle {
        color: page.canvasColor
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

    function refresh() {
        const payload = buildPayload()
        page.currentPayload = payload
        if (payload.length === 0) {
            qrImage.source = ""
            page.capacity = ({ fits: false, version: -1, maxBytes: 0, usedBytes: 0 })
            return
        }
        page.capacity = qrGenerator.capacityInfo(payload, eccSelector.currentIndex)
        qrGenerator.requestQr(payload, eccSelector.currentIndex, 640,
                              fgColor.color, bgColor.color)
    }

    function savePngTo(url) {
        const img = qrGenerator.generateQr(page.currentPayload, eccSelector.currentIndex,
                                           2048, fgColor.color, bgColor.color)
        qrGenerator.saveImage(img, url)
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

    Connections {
        target: qrGenerator
        function onQrReady(image, text) {
            if (text === page.currentPayload)
                qrImage.source = "image://qrcode/" + encodeURIComponent(text)
                                 + "?e=" + eccSelector.currentIndex
                                 + "&f=" + page.colorHex(fgColor.color)
                                 + "&b=" + page.colorHex(bgColor.color)
        }
        function onQrFailed(text, reason) {
            if (text === page.currentPayload)
                qrImage.source = ""
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        GridLayout {
            width: Math.min(page.width, page.wideLayout ? 1160 : 600)
            x: Math.max(0, (page.width - width) / 2)
            columns: page.wideLayout ? 2 : 1
            columnSpacing: 28
            rowSpacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                Layout.row: 0
                Layout.column: 0
                Layout.rowSpan: page.wideLayout ? 3 : 1
                Layout.preferredWidth: page.wideLayout ? 540 : -1
                Layout.leftMargin: page.wideLayout ? 28 : 20
                Layout.rightMargin: page.wideLayout ? 0 : 20
                Layout.topMargin: page.wideLayout ? 28 : 20
                Layout.bottomMargin: page.wideLayout ? 28 : 0
                spacing: 12

                Label {
                    text: qsTr("Create a QR code")
                    font.pixelSize: page.wideLayout ? 28 : 23
                    font.bold: true
                }

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Build a code for sharing, then export it as an image")
                    color: page.mutedColor
                    wrapMode: Text.WordWrap
                    Layout.bottomMargin: 8
                }

                Label {
                    text: qsTr("Content type")
                    font.bold: true
                }

                ComboBox {
                    id: typeSelector
                    Layout.fillWidth: true
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

                // --- Generic single-line field (text/url/email) --------------
                TextField {
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
                    Accessible.name: qsTr("Primary content field")
                    onTextChanged: page.refresh()
                }

                // --- Phone (contact) fields ----------------------------------
                TextField {
                    id: fieldContactName
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typePhone
                    placeholderText: qsTr("Name (optional)")
                    Accessible.name: qsTr("Contact name")
                    onTextChanged: page.refresh()
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typePhone
                    spacing: 12

                    TextField {
                        id: fieldCountryCode
                        Layout.preferredWidth: 96
                        placeholderText: qsTr("+1")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        Accessible.name: qsTr("Country code")
                        onTextChanged: page.refresh()
                    }
                    TextField {
                        id: fieldPhoneNumber
                        Layout.fillWidth: true
                        placeholderText: qsTr("Phone number")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        Accessible.name: qsTr("Phone number")
                        onTextChanged: page.refresh()
                    }
                }

                // --- SMS number fields ---------------------------------------
                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeSms
                    spacing: 12

                    TextField {
                        id: fieldSmsCountryCode
                        Layout.preferredWidth: 96
                        placeholderText: qsTr("+1")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        Accessible.name: qsTr("Country code")
                        onTextChanged: page.refresh()
                    }
                    TextField {
                        id: fieldSmsNumber
                        Layout.fillWidth: true
                        placeholderText: qsTr("Recipient number")
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        Accessible.name: qsTr("Recipient number")
                        onTextChanged: page.refresh()
                    }
                }

                // --- Email / SMS extras --------------------------------------
                TextField {
                    id: fieldSubject
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeEmail
                    placeholderText: qsTr("Subject")
                    Accessible.name: qsTr("Email subject")
                    onTextChanged: page.refresh()
                }

                TextField {
                    id: fieldBody
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeEmail
                             || typeSelector.currentIndex === page.typeSms
                    placeholderText: typeSelector.currentIndex === page.typeSms
                                     ? qsTr("Message") : qsTr("Body")
                    Accessible.name: qsTr("Message body")
                    onTextChanged: page.refresh()
                }

                // --- Wi-Fi fields --------------------------------------------
                TextField {
                    id: fieldSsid
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeWifi
                    placeholderText: qsTr("Network name (SSID)")
                    Accessible.name: qsTr("Wi-Fi network name")
                    onTextChanged: page.refresh()
                }

                TextField {
                    id: fieldPassword
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeWifi
                             && wifiAuth.currentValue !== "none"
                    placeholderText: qsTr("Password")
                    echoMode: TextInput.Password
                    Accessible.name: qsTr("Wi-Fi password")
                    onTextChanged: page.refresh()
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
                    spacing: 12

                    TextField {
                        id: fieldLat
                        Layout.fillWidth: true
                        placeholderText: qsTr("Latitude")
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        Accessible.name: qsTr("Latitude")
                        onTextChanged: page.refresh()
                    }
                    TextField {
                        id: fieldLon
                        Layout.fillWidth: true
                        placeholderText: qsTr("Longitude")
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        Accessible.name: qsTr("Longitude")
                        onTextChanged: page.refresh()
                    }
                }

                TextField {
                    id: fieldStreet
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeAddress
                    placeholderText: qsTr("Street")
                    Accessible.name: qsTr("Street")
                    onTextChanged: page.refresh()
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeAddress
                    spacing: 12

                    TextField {
                        id: fieldBuilding
                        Layout.fillWidth: true
                        placeholderText: qsTr("Building number")
                        Accessible.name: qsTr("Building number")
                        onTextChanged: page.refresh()
                    }
                    TextField {
                        id: fieldPostal
                        Layout.fillWidth: true
                        placeholderText: qsTr("Postal code")
                        Accessible.name: qsTr("Postal code")
                        onTextChanged: page.refresh()
                    }
                }

                TextField {
                    id: fieldCity
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeAddress
                    placeholderText: qsTr("City")
                    Accessible.name: qsTr("City")
                    onTextChanged: page.refresh()
                }

                TextField {
                    id: fieldCountry
                    Layout.fillWidth: true
                    visible: typeSelector.currentIndex === page.typeGeo
                             && geoModeSelector.currentIndex === page.geoModeAddress
                    placeholderText: qsTr("Country")
                    Accessible.name: qsTr("Country")
                    onTextChanged: page.refresh()
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
                        qsTr("Low (7%)"),
                        qsTr("Medium (15%)"),
                        qsTr("Quartile (25%)"),
                        qsTr("High (30%)")
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
            }

            // --- Preview -----------------------------------------------------
            Rectangle {
                Layout.row: page.wideLayout ? 0 : 1
                Layout.column: page.wideLayout ? 1 : 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: page.wideLayout ? 72 : 8
                Layout.preferredWidth: page.wideLayout ? 360 : 280
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
                    sourceSize.width: 1024
                    sourceSize.height: 1024
                    smooth: true
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                    Accessible.role: Accessible.Graphic
                    Accessible.name: qsTr("Generated QR code preview")
                }
            }

            Button {
                Layout.row: page.wideLayout ? 1 : 2
                Layout.column: page.wideLayout ? 1 : 0
                Layout.fillWidth: true
                Layout.leftMargin: page.wideLayout ? 0 : 20
                Layout.rightMargin: page.wideLayout ? 28 : 20
                Layout.bottomMargin: 24
                text: qsTr("Save as PNG")
                enabled: qrImage.source.toString().length > 0 && page.capacity.fits
                Material.background: enabled ? page.primaryColor
                    : Qt.rgba(page.mutedColor.r, page.mutedColor.g, page.mutedColor.b, 0.16)
                Material.foreground: enabled ? page.primaryTextColor : page.mutedColor
                Accessible.name: qsTr("Save QR code as PNG")
                onClicked: {
                    if (Qt.platform.os === "android" || Qt.platform.os === "ios")
                        saveDialog.open()
                    else
                        savePicker.openAt(page.folderUrl())
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
        suggestedName: "qrcode.png"
        primaryColor: page.primaryColor
        primaryTextColor: page.primaryTextColor
        mutedColor: page.mutedColor
        onAccepted: (file) => page.savePngTo(file)
    }
}
