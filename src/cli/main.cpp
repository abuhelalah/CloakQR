#include "qrdata.h"
#include "qrgenerator.h"
#include "cloakqr_version.h"

#include <QColor>
#include <QCoreApplication>
#include <QCommandLineParser>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>

#include <cstdio>

using cloakqr::QrData;
using cloakqr::QrEcc;

namespace {

QTextStream& err()
{
    static QTextStream s(stderr);
    return s;
}

int eccFromLetter(const QString& letter, bool* ok)
{
    *ok = true;
    const QString upper = letter.toUpper();
    if (upper == QLatin1String("L")) return 0;
    if (upper == QLatin1String("M")) return 1;
    if (upper == QLatin1String("Q")) return 2;
    if (upper == QLatin1String("H")) return 3;
    *ok = false;
    return 1;
}

QrData::WifiAuth wifiAuthFrom(const QString& value)
{
    const QString lower = value.toLower();
    if (lower == QLatin1String("wep")) return QrData::WifiAuth::Wep;
    if (lower == QLatin1String("none") || lower == QLatin1String("nopass"))
        return QrData::WifiAuth::None;
    return QrData::WifiAuth::Wpa;
}

QString readStdin()
{
    QTextStream in(stdin);
    return in.readAll();
}

} // namespace

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("cloakqr"));
    QCoreApplication::setApplicationVersion(QStringLiteral(CLOAKQR_VERSION));

    QCommandLineParser parser;
    parser.setApplicationDescription(
        QStringLiteral("CloakQR - offline, privacy-first QR code generator."));
    parser.addHelpOption();
    parser.addVersionOption();

    parser.addOptions({
        {QStringLiteral("text"), QStringLiteral("Encode plain text."), QStringLiteral("text")},
        {QStringLiteral("url"), QStringLiteral("Encode a URL."), QStringLiteral("url")},
        {QStringLiteral("email"), QStringLiteral("Encode an email address."), QStringLiteral("address")},
        {QStringLiteral("subject"), QStringLiteral("Email subject."), QStringLiteral("subject")},
        {QStringLiteral("body"), QStringLiteral("Email body."), QStringLiteral("body")},
        {QStringLiteral("phone"), QStringLiteral("Encode a phone number."), QStringLiteral("number")},
        {QStringLiteral("sms"), QStringLiteral("Encode an SMS number."), QStringLiteral("number")},
        {QStringLiteral("message"), QStringLiteral("SMS message body."), QStringLiteral("message")},
        {QStringLiteral("geo"), QStringLiteral("Encode a geo location as LAT,LON."), QStringLiteral("lat,lon")},
        {QStringLiteral("wifi-ssid"), QStringLiteral("Encode WiFi credentials (SSID)."), QStringLiteral("ssid")},
        {QStringLiteral("wifi-password"), QStringLiteral("WiFi password."), QStringLiteral("password")},
        {QStringLiteral("wifi-auth"), QStringLiteral("WiFi auth: WPA, WEP or none."), QStringLiteral("auth"), QStringLiteral("WPA")},
        {QStringLiteral("wifi-hidden"), QStringLiteral("Mark the WiFi network as hidden.")},
        {QStringLiteral("stdin"), QStringLiteral("Read text content from standard input.")},
        {QStringLiteral("output"), QStringLiteral("Output file (PNG or SVG). Use '-' for stdout."), QStringLiteral("file")},
        {QStringLiteral("format"), QStringLiteral("Output format: png or svg."), QStringLiteral("format")},
        {QStringLiteral("ecc"), QStringLiteral("Error correction: L, M, Q or H."), QStringLiteral("level"), QStringLiteral("M")},
        {QStringLiteral("size"), QStringLiteral("Target image size in pixels (PNG)."), QStringLiteral("px"), QStringLiteral("512")},
        {QStringLiteral("fg"), QStringLiteral("Foreground colour."), QStringLiteral("colour"), QStringLiteral("#000000")},
        {QStringLiteral("bg"), QStringLiteral("Background colour."), QStringLiteral("colour"), QStringLiteral("#ffffff")},
    });

    parser.process(app);

    // --- Resolve content -------------------------------------------------
    QString payload;
    int sources = 0;
    const auto has = [&](const char* name) { return parser.isSet(QLatin1String(name)); };

    if (parser.isSet(QStringLiteral("stdin"))) { payload = readStdin(); ++sources; }
    if (has("text")) { payload = QrData::text(parser.value(QStringLiteral("text"))); ++sources; }
    if (has("url")) { payload = QrData::url(parser.value(QStringLiteral("url"))); ++sources; }
    if (has("email")) {
        payload = QrData::email(parser.value(QStringLiteral("email")),
                                parser.value(QStringLiteral("subject")),
                                parser.value(QStringLiteral("body")));
        ++sources;
    }
    if (has("phone")) { payload = QrData::phone(parser.value(QStringLiteral("phone"))); ++sources; }
    if (has("sms")) {
        payload = QrData::sms(parser.value(QStringLiteral("sms")),
                              parser.value(QStringLiteral("message")));
        ++sources;
    }
    if (has("geo")) {
        const QStringList parts = parser.value(QStringLiteral("geo")).split(QLatin1Char(','));
        if (parts.size() != 2) {
            err() << "error: --geo expects LAT,LON\n";
            return 2;
        }
        payload = QrData::geo(parts[0].trimmed().toDouble(), parts[1].trimmed().toDouble());
        ++sources;
    }
    if (has("wifi-ssid")) {
        payload = QrData::wifi(parser.value(QStringLiteral("wifi-ssid")),
                               parser.value(QStringLiteral("wifi-password")),
                               wifiAuthFrom(parser.value(QStringLiteral("wifi-auth"))),
                               parser.isSet(QStringLiteral("wifi-hidden")));
        ++sources;
    }

    if (sources == 0) {
        err() << "error: no content specified. See --help.\n";
        return 2;
    }
    if (sources > 1) {
        err() << "error: specify exactly one content type.\n";
        return 2;
    }
    if (payload.isEmpty()) {
        err() << "error: content is empty.\n";
        return 2;
    }

    // --- Options ---------------------------------------------------------
    bool eccOk = false;
    const int ecc = eccFromLetter(parser.value(QStringLiteral("ecc")), &eccOk);
    if (!eccOk) {
        err() << "error: --ecc must be L, M, Q or H.\n";
        return 2;
    }

    const QColor fg(parser.value(QStringLiteral("fg")));
    const QColor bg(parser.value(QStringLiteral("bg")));
    if (!fg.isValid() || !bg.isValid()) {
        err() << "error: invalid --fg/--bg colour.\n";
        return 2;
    }

    const QString output = parser.value(QStringLiteral("output"));
    QString format = parser.value(QStringLiteral("format")).toLower();
    if (format.isEmpty()) {
        const QString suffix = QFileInfo(output).suffix().toLower();
        format = (suffix == QLatin1String("svg")) ? QStringLiteral("svg") : QStringLiteral("png");
    }
    if (format != QLatin1String("png") && format != QLatin1String("svg")) {
        err() << "error: --format must be png or svg.\n";
        return 2;
    }

    QrGenerator generator;
    if (generator.requiredVersion(payload, ecc) < 0) {
        err() << "error: content is too large to encode at ECC "
              << parser.value(QStringLiteral("ecc")).toUpper() << ".\n";
        return 1;
    }

    // --- Emit output -----------------------------------------------------
    if (format == QLatin1String("svg")) {
        const QString svg = generator.generateSvg(payload, ecc, 4, fg, bg);
        if (output.isEmpty() || output == QLatin1String("-")) {
            QTextStream(stdout) << svg;
        } else {
            QFile file(output);
            if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
                err() << "error: cannot write " << output << "\n";
                return 1;
            }
            QTextStream(&file) << svg;
        }
        return 0;
    }

    // PNG
    if (output.isEmpty() || output == QLatin1String("-")) {
        err() << "error: PNG output requires --output FILE.\n";
        return 2;
    }
    const int size = parser.value(QStringLiteral("size")).toInt();
    const QImage image = generator.generateQr(payload, ecc, size > 0 ? size : 512, fg, bg);
    if (image.isNull() || !generator.saveImage(image, QUrl::fromLocalFile(output))) {
        err() << "error: failed to generate or save PNG.\n";
        return 1;
    }
    return 0;
}