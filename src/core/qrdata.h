#pragma once

#include "qrencoder.h"

#include <QString>

namespace cloakqr {

// Builds and validates the textual payloads that are encoded into QR codes for
// the supported content types, and reports capacity information for a payload.
//
// All builders return canonical, standards-compliant strings (e.g. the
// "WIFI:" and "geo:" URI schemes) with the required characters escaped.
class QrData
{
public:
    enum class Type {
        Text,
        Url,
        Email,
        Phone,
        Sms,
        WiFi,
        VCard,
        Geo
    };

    enum class WifiAuth {
        None,
        Wep,
        Wpa
    };

    struct Capacity {
        bool fits = false;   // whether the payload fits in a version-40 symbol
        int version = -1;    // smallest fitting version, or -1
        int maxBytes = 0;    // byte-mode capacity at that version/ECC
        int usedBytes = 0;   // UTF-8 byte length of the payload
    };

    // Payload builders. Each returns the string that should be encoded.
    static QString text(const QString& value);
    static QString url(const QString& value);
    static QString email(const QString& address, const QString& subject = QString(),
                         const QString& body = QString());
    static QString phone(const QString& number);
    static QString sms(const QString& number, const QString& message = QString());
    static QString wifi(const QString& ssid, const QString& password, WifiAuth auth,
                        bool hidden = false);
    static QString geo(double latitude, double longitude);
    // Location payload carrying an optional place/address label ("?q=..."),
    // which map apps use as the search query when coordinates are 0,0.
    static QString geo(double latitude, double longitude, const QString& label);
    static QString vcard(const QString& fullName, const QString& organization = QString(),
                         const QString& phone = QString(), const QString& email = QString(),
                         const QString& url = QString());

    // Returns true when the payload is non-empty and fits in a version-40
    // symbol at the given ECC level.
    static bool isValid(const QString& payload, QrEcc ecc = QrEcc::Medium);

    // Reports capacity details for the payload at the given ECC level.
    static Capacity capacity(const QString& payload, QrEcc ecc = QrEcc::Medium);

private:
    // Escapes the MECARD/WIFI reserved characters: \ ; , : "
    static QString escapeMecard(const QString& value);
    // Escapes vCard reserved characters: \ ; , and newlines.
    static QString escapeVCard(const QString& value);
};

} // namespace cloakqr
