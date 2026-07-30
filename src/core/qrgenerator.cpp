#include "qrgenerator.h"

#include "logger.h"
#include "qrdata.h"
#include "qrencoder.h"

#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QtConcurrent/QtConcurrentRun>

namespace {

cloakqr::QrEcc toEcc(int eccLevel)
{
    switch (eccLevel) {
    case 0: return cloakqr::QrEcc::Low;
    case 2: return cloakqr::QrEcc::Quartile;
    case 3: return cloakqr::QrEcc::High;
    case 1:
    default: return cloakqr::QrEcc::Medium;
    }
}

// Renders a placed QR symbol to an RGB image at the requested target size.
// The symbol is drawn one pixel per module and then nearest-neighbour scaled
// so the output stays perfectly crisp at any size.
QImage renderImage(const cloakqr::QrCode& code, int targetSize, int quietZone,
                   const QColor& foreground, const QColor& background)
{
    const int n = code.size();
    const int dim = n + 2 * quietZone;

    QImage base(dim, dim, QImage::Format_RGB32);
    base.fill(background);
    const QRgb fg = foreground.rgb();
    for (int y = 0; y < n; ++y)
        for (int x = 0; x < n; ++x)
            if (code.module(x, y))
                base.setPixel(x + quietZone, y + quietZone, fg);

    const int moduleSize = qMax(1, targetSize / dim);
    if (moduleSize == 1)
        return base;
    return base.scaled(dim * moduleSize, dim * moduleSize,
                       Qt::IgnoreAspectRatio, Qt::FastTransformation);
}

} // namespace

QrGenerator::QrGenerator(QObject* parent)
    : QObject(parent)
{
}

QImage QrGenerator::generateQr(const QString& text, int eccLevel, int targetSize,
                               const QColor& foreground, const QColor& background) const
{
    const cloakqr::QrCode code = cloakqr::QrEncoder::encodeText(text, toEcc(eccLevel));
    if (!code.isValid()) {
        qCWarning(cloakqrCore) << "QR generation failed: content does not fit";
        return QImage();
    }
    return renderImage(code, targetSize, 4, foreground, background);
}

QString QrGenerator::generateSvg(const QString& text, int eccLevel, int quietZone,
                                 const QColor& foreground, const QColor& background) const
{
    const cloakqr::QrCode code = cloakqr::QrEncoder::encodeText(text, toEcc(eccLevel));
    if (!code.isValid())
        return QString();

    const int n = code.size();
    const int dim = n + 2 * quietZone;

    QString path;
    for (int y = 0; y < n; ++y) {
        int x = 0;
        while (x < n) {
            if (!code.module(x, y)) {
                ++x;
                continue;
            }
            int run = 0;
            while (x + run < n && code.module(x + run, y))
                ++run;
            path += QStringLiteral("M%1 %2h%3v1h-%3z")
                        .arg(x + quietZone)
                        .arg(y + quietZone)
                        .arg(run);
            x += run;
        }
    }

    QString svg;
    svg += QStringLiteral("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    svg += QStringLiteral(
               "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%1\" height=\"%1\" "
               "viewBox=\"0 0 %1 %1\" shape-rendering=\"crispEdges\">\n")
               .arg(dim);
    svg += QStringLiteral("<rect width=\"%1\" height=\"%1\" fill=\"%2\"/>\n")
               .arg(dim)
               .arg(background.name());
    if (!path.isEmpty())
        svg += QStringLiteral("<path d=\"%1\" fill=\"%2\"/>\n").arg(path, foreground.name());
    svg += QStringLiteral("</svg>\n");
    return svg;
}

int QrGenerator::requiredVersion(const QString& text, int eccLevel) const
{
    return cloakqr::QrEncoder::minimumVersion(text, toEcc(eccLevel));
}

void QrGenerator::requestQr(const QString& text, int eccLevel, int targetSize,
                            const QColor& foreground, const QColor& background)
{
    auto* watcher = new QFutureWatcher<QImage>(this);
    connect(watcher, &QFutureWatcher<QImage>::finished, this, [this, watcher, text]() {
        const QImage image = watcher->result();
        watcher->deleteLater();
        if (image.isNull())
            emit qrFailed(text, tr("Content is empty or too large to encode."));
        else
            emit qrReady(image, text);
    });

    const cloakqr::QrEcc ecc = toEcc(eccLevel);
    watcher->setFuture(QtConcurrent::run([text, ecc, targetSize, foreground, background]() {
        const cloakqr::QrCode code = cloakqr::QrEncoder::encodeText(text, ecc);
        if (!code.isValid())
            return QImage();
        return renderImage(code, targetSize, 4, foreground, background);
    }));
}

bool QrGenerator::saveImage(const QImage& image, const QUrl& outputUrl) const
{
    if (image.isNull())
        return false;

    const QString path = outputUrl.isLocalFile() ? outputUrl.toLocalFile() : outputUrl.toString();
    const QString suffix = QFileInfo(path).suffix().toUpper();
    const QByteArray format = suffix.isEmpty() ? QByteArray("PNG") : suffix.toLatin1();

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        qCWarning(cloakqrCore) << "Unable to open output file:" << path;
        return false;
    }
    const bool ok = image.save(&file, format.constData());
    file.close();
    return ok;
}

QString QrGenerator::textPayload(const QString& value) const
{
    return cloakqr::QrData::text(value);
}

QString QrGenerator::urlPayload(const QString& value) const
{
    return cloakqr::QrData::url(value);
}

QString QrGenerator::emailPayload(const QString& address, const QString& subject,
                                  const QString& body) const
{
    return cloakqr::QrData::email(address, subject, body);
}

QString QrGenerator::phonePayload(const QString& number) const
{
    return cloakqr::QrData::phone(number);
}

QString QrGenerator::smsPayload(const QString& number, const QString& message) const
{
    return cloakqr::QrData::sms(number, message);
}

QString QrGenerator::wifiPayload(const QString& ssid, const QString& password,
                                 const QString& auth, bool hidden) const
{
    const QString lower = auth.toLower();
    cloakqr::QrData::WifiAuth mode = cloakqr::QrData::WifiAuth::Wpa;
    if (lower == QLatin1String("wep"))
        mode = cloakqr::QrData::WifiAuth::Wep;
    else if (lower == QLatin1String("none") || lower == QLatin1String("nopass"))
        mode = cloakqr::QrData::WifiAuth::None;
    return cloakqr::QrData::wifi(ssid, password, mode, hidden);
}

QString QrGenerator::geoPayload(double latitude, double longitude) const
{
    return cloakqr::QrData::geo(latitude, longitude);
}

QString QrGenerator::vcardPayload(const QString& fullName, const QString& organization,
                                  const QString& phone, const QString& email,
                                  const QString& url) const
{
    return cloakqr::QrData::vcard(fullName, organization, phone, email, url);
}

QVariantMap QrGenerator::capacityInfo(const QString& payload, int eccLevel) const
{
    const cloakqr::QrData::Capacity cap = cloakqr::QrData::capacity(payload, toEcc(eccLevel));
    QVariantMap map;
    map.insert(QStringLiteral("fits"), cap.fits);
    map.insert(QStringLiteral("version"), cap.version);
    map.insert(QStringLiteral("maxBytes"), cap.maxBytes);
    map.insert(QStringLiteral("usedBytes"), cap.usedBytes);
    return map;
}
