#include "qrdata.h"

#include <QUrl>

namespace cloakqr {

QString QrData::escapeMecard(const QString& value)
{
    QString result;
    result.reserve(value.size());
    for (const QChar ch : value) {
        if (ch == QLatin1Char('\\') || ch == QLatin1Char(';')
            || ch == QLatin1Char(',') || ch == QLatin1Char(':')
            || ch == QLatin1Char('"'))
            result.append(QLatin1Char('\\'));
        result.append(ch);
    }
    return result;
}

QString QrData::escapeVCard(const QString& value)
{
    QString result;
    result.reserve(value.size());
    for (const QChar ch : value) {
        if (ch == QLatin1Char('\\') || ch == QLatin1Char(';') || ch == QLatin1Char(','))
            result.append(QLatin1Char('\\'));
        if (ch == QLatin1Char('\n'))
            result.append(QStringLiteral("\\n"));
        else
            result.append(ch);
    }
    return result;
}

QString QrData::text(const QString& value)
{
    return value;
}

QString QrData::url(const QString& value)
{
    const QString trimmed = value.trimmed();
    if (trimmed.isEmpty())
        return trimmed;
    if (trimmed.contains(QStringLiteral("://")))
        return trimmed;
    return QStringLiteral("https://") + trimmed;
}

QString QrData::email(const QString& address, const QString& subject, const QString& body)
{
    QString result = QStringLiteral("mailto:") + address;
    QStringList query;
    if (!subject.isEmpty())
        query << QStringLiteral("subject=") + QString::fromUtf8(QUrl::toPercentEncoding(subject));
    if (!body.isEmpty())
        query << QStringLiteral("body=") + QString::fromUtf8(QUrl::toPercentEncoding(body));
    if (!query.isEmpty())
        result += QLatin1Char('?') + query.join(QLatin1Char('&'));
    return result;
}

QString QrData::phone(const QString& number)
{
    return QStringLiteral("tel:") + number.simplified().remove(QLatin1Char(' '));
}

QString QrData::sms(const QString& number, const QString& message)
{
    QString result = QStringLiteral("smsto:") + number.simplified().remove(QLatin1Char(' '));
    if (!message.isEmpty())
        result += QLatin1Char(':') + message;
    return result;
}

QString QrData::wifi(const QString& ssid, const QString& password, WifiAuth auth, bool hidden)
{
    QString type;
    switch (auth) {
    case WifiAuth::None: type = QStringLiteral("nopass"); break;
    case WifiAuth::Wep: type = QStringLiteral("WEP"); break;
    case WifiAuth::Wpa: type = QStringLiteral("WPA"); break;
    }

    QString result = QStringLiteral("WIFI:S:") + escapeMecard(ssid) + QLatin1Char(';');
    result += QStringLiteral("T:") + type + QLatin1Char(';');
    if (auth != WifiAuth::None && !password.isEmpty())
        result += QStringLiteral("P:") + escapeMecard(password) + QLatin1Char(';');
    if (hidden)
        result += QStringLiteral("H:true;");
    result += QLatin1Char(';');
    return result;
}

QString QrData::geo(double latitude, double longitude)
{
    return QStringLiteral("geo:") + QString::number(latitude, 'f', 6)
        + QLatin1Char(',') + QString::number(longitude, 'f', 6);
}

QString QrData::vcard(const QString& fullName, const QString& organization,
                      const QString& phone, const QString& email, const QString& url)
{
    QString result = QStringLiteral("BEGIN:VCARD\nVERSION:3.0\n");
    result += QStringLiteral("N:") + escapeVCard(fullName) + QLatin1Char('\n');
    result += QStringLiteral("FN:") + escapeVCard(fullName) + QLatin1Char('\n');
    if (!organization.isEmpty())
        result += QStringLiteral("ORG:") + escapeVCard(organization) + QLatin1Char('\n');
    if (!phone.isEmpty())
        result += QStringLiteral("TEL:") + escapeVCard(phone) + QLatin1Char('\n');
    if (!email.isEmpty())
        result += QStringLiteral("EMAIL:") + escapeVCard(email) + QLatin1Char('\n');
    if (!url.isEmpty())
        result += QStringLiteral("URL:") + escapeVCard(url) + QLatin1Char('\n');
    result += QStringLiteral("END:VCARD");
    return result;
}

bool QrData::isValid(const QString& payload, QrEcc ecc)
{
    return !payload.isEmpty() && QrEncoder::minimumVersion(payload, ecc) > 0;
}

QrData::Capacity QrData::capacity(const QString& payload, QrEcc ecc)
{
    Capacity info;
    info.usedBytes = payload.toUtf8().size();
    info.version = QrEncoder::minimumVersion(payload, ecc);
    info.fits = info.version > 0;
    if (info.fits)
        info.maxBytes = QrEncoder::byteModeCapacity(info.version, ecc);
    return info;
}

} // namespace cloakqr
