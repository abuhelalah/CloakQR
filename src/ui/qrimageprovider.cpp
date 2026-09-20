#include "qrimageprovider.h"

#include "qrgenerator.h"

#include <QColor>
#include <QFutureWatcher>
#include <QUrl>
#include <QtConcurrent/QtConcurrentRun>

namespace {

// Parsed "image://qrcode/" request. The id is
// "<percent-encoded payload>?e=<ecc>&f=<hex>&b=<hex>"; the query portion is
// optional so a bare payload still renders with the defaults.
struct QrRequest
{
    QString text;
    int ecc = 1;
    QColor foreground{Qt::black};
    QColor background{Qt::white};
};

QrRequest parseRequest(const QString& id)
{
    QrRequest req;

    const int query = id.indexOf(QLatin1Char('?'));
    const QString encoded = query >= 0 ? id.left(query) : id;
    req.text = QUrl::fromPercentEncoding(encoded.toUtf8());

    if (query >= 0) {
        const QStringList params = id.mid(query + 1).split(QLatin1Char('&'), Qt::SkipEmptyParts);
        for (const QString& param : params) {
            const int eq = param.indexOf(QLatin1Char('='));
            if (eq < 0)
                continue;
            const QString key = param.left(eq);
            const QString value = param.mid(eq + 1);
            if (key == QLatin1String("e"))
                req.ecc = value.toInt();
            else if (key == QLatin1String("f"))
                req.foreground = QColor(QStringLiteral("#") + value);
            else if (key == QLatin1String("b"))
                req.background = QColor(QStringLiteral("#") + value);
        }
    }

    return req;
}

int targetFor(const QSize& requestedSize)
{
    const int target = requestedSize.isValid() ? qMax(requestedSize.width(), requestedSize.height())
                                               : 512;
    return target > 0 ? target : 512;
}

} // namespace

QrImageResponse::QrImageResponse(const QString& text, int ecc, int targetSize,
                                 const QColor& foreground, const QColor& background,
                                 QrGenerator* generator)
{
    auto* watcher = new QFutureWatcher<QImage>(this);
    connect(watcher, &QFutureWatcher<QImage>::finished, this, [this, watcher]() {
        const QImage image = watcher->result();
        watcher->deleteLater();

        // A superseded request was cancelled; drop the stale result.
        if (m_cancelled.loadAcquire())
            return;

        if (image.isNull()) {
            m_error = QStringLiteral("The QR code could not be generated.");
        } else {
            // The generator produces Format_RGB32. Convert to the scene
            // graph's native premultiplied format before hand-off: some
            // Android/software-GL drivers mis-upload 32-bit RGB as an
            // all-black texture, which is how the preview used to break on
            // the emulator.
            m_image = image.convertToFormat(QImage::Format_ARGB32_Premultiplied);
        }

        emit finished();  // the engine consumes (and frees) the response here
    });

    watcher->setFuture(QtConcurrent::run([text, ecc, targetSize, foreground, background, generator]() {
        return generator->generateQr(text, ecc, targetSize, foreground, background);
    }));
}

QString QrImageResponse::errorString() const
{
    return m_error;
}

QQuickTextureFactory* QrImageResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

void QrImageResponse::cancel()
{
    m_cancelled.storeRelease(1);
    QQuickImageResponse::cancel();
}

QrImageProvider::QrImageProvider(QrGenerator* generator)
    : QQuickAsyncImageProvider()
    , m_generator(generator)
{
}

QImage QrImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    const QrRequest req = parseRequest(id);
    QImage image = m_generator->generateQr(req.text, req.ecc, targetFor(requestedSize),
                                           req.foreground, req.background);

    if (size)
        *size = image.size();

    // Same normalisation as the async path: RGB32 can upload as black on some
    // GL/GLES drivers, so hand QML the scene graph's native premultiplied
    // format.
    return image.convertToFormat(QImage::Format_ARGB32_Premultiplied);
}

QQuickImageResponse* QrImageProvider::requestImageResponse(const QString& id, const QSize& requestedSize)
{
    const QrRequest req = parseRequest(id);
    return new QrImageResponse(req.text, req.ecc, targetFor(requestedSize),
                               req.foreground, req.background, m_generator);
}
