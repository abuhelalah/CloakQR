#include "qrdecoder.h"

#include <BarcodeFormat.h>
#include <ImageView.h>
#include <ReadBarcode.h>

#include <QByteArray>
#include <QBuffer>
#include <QFile>
#include <QFutureWatcher>
#include <QImageReader>
#include <QUrl>
#include <QVideoFrame>
#include <QVideoFrameFormat>
#include <QVideoSink>
#include <QtConcurrent/QtConcurrentRun>

namespace {

constexpr qint64 kMaxImageBytes = 32 * 1024 * 1024;
constexpr int kMaxSelectedImageDimension = 2048;
constexpr int kFrameIntervalMs = 250;
constexpr int kMaxVideoFrameDimension = 1280;

struct DecodeResult
{
    QString text;
    QString error;
};

// Runs zxing over an 8-bit luma buffer. tryHarder enables a more exhaustive
// search (used for still images); live frames use the lighter default so each
// failed frame stays cheap. tryRotate is intentionally never set: QR detection
// is rotation-invariant, so it only adds retry work for no benefit.
DecodeResult decodeLum(const uchar* bits, int width, int height, int stride, bool tryHarder)
{
    const ZXing::ImageView imageView(bits, width, height, ZXing::ImageFormat::Lum, stride);
    ZXing::DecodeHints options = ZXing::DecodeHints().setFormats(ZXing::BarcodeFormat::QRCode);
    if (tryHarder)
        options.setTryHarder(true);
    const ZXing::Result result = ZXing::ReadBarcode(imageView, options);
    if (!result.isValid())
        return {{}, QrDecoder::tr("No QR code was found in the image.")};

    const QByteArray bytes = QByteArray::fromStdString(result.text());
    const QString text = QString::fromUtf8(bytes);
    if (text.toUtf8() != bytes)
        return {{}, QrDecoder::tr("The QR code does not contain valid UTF-8 text.")};

    return {text, {}};
}

DecodeResult decodeQrImage(const QImage& image, bool tryHarder)
{
    if (image.isNull())
        return {{}, QrDecoder::tr("The selected image could not be opened.")};

    const QImage grayscale = image.convertToFormat(QImage::Format_Grayscale8);
    return decodeLum(grayscale.constBits(), grayscale.width(), grayscale.height(),
                     grayscale.bytesPerLine(), tryHarder);
}

// True when plane 0 of a YUV frame is a full-resolution 8-bit luma plane that
// zxing can consume directly (planar/semi-planar 4:2:0 and 4:2:2, and luma-only).
bool hasDirectLumaPlane(QVideoFrameFormat::PixelFormat fmt)
{
    switch (fmt) {
    case QVideoFrameFormat::Format_YUV420P:
    case QVideoFrameFormat::Format_YUV422P:
    case QVideoFrameFormat::Format_YV12:
    case QVideoFrameFormat::Format_NV12:
    case QVideoFrameFormat::Format_NV21:
    case QVideoFrameFormat::Format_IMC1:
    case QVideoFrameFormat::Format_IMC2:
    case QVideoFrameFormat::Format_IMC3:
    case QVideoFrameFormat::Format_IMC4:
    case QVideoFrameFormat::Format_Y8:
        return true;
    default:
        return false;
    }
}

QImage scaledForDecode(const QImage& image, int maxDimension)
{
    if (maxDimension <= 0
        || (image.width() <= maxDimension && image.height() <= maxDimension)) {
        return image;
    }

    return image.scaled(maxDimension, maxDimension,
                        Qt::KeepAspectRatio, Qt::FastTransformation);
}

QImage loadImage(const QUrl& imageUrl)
{
    const QString path = imageUrl.isLocalFile() ? imageUrl.toLocalFile() : imageUrl.toString();
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return {};
    QByteArray data = file.read(kMaxImageBytes + 1);
    if (data.size() > kMaxImageBytes)
        return {};

    // Wrap the bytes directly instead of QBuffer::setData(), which would copy
    // the whole (up to 32 MiB) buffer again. `data` outlives `buffer`.
    QBuffer buffer(&data);
    if (!buffer.open(QIODevice::ReadOnly))
        return {};

    QImageReader reader(&buffer);
    reader.setAutoTransform(true);
    QSize imageSize = reader.size();
    if (imageSize.isValid()
        && (imageSize.width() > kMaxSelectedImageDimension
            || imageSize.height() > kMaxSelectedImageDimension)) {
        imageSize.scale(kMaxSelectedImageDimension, kMaxSelectedImageDimension,
                        Qt::KeepAspectRatio);
        reader.setScaledSize(imageSize);
    }
    return reader.read();
}

} // namespace

QrDecoder::QrDecoder(QObject* parent)
    : QObject(parent)
{
}

void QrDecoder::handleDecodedText(const QString& text)
{
    const QString trimmed = text.trimmed();
    const QUrl candidate(trimmed, QUrl::StrictMode);
    const bool hasWebScheme = trimmed.startsWith(QStringLiteral("http://"), Qt::CaseInsensitive)
        || trimmed.startsWith(QStringLiteral("https://"), Qt::CaseInsensitive);

    if (hasWebScheme && candidate.isValid() && !candidate.host().isEmpty()) {
        emit urlDetected(candidate.toString());
    } else {
        emit textDetected(trimmed);
    }
}

bool QrDecoder::decodeImage(const QImage& image)
{
    const DecodeResult result = decodeQrImage(image, true);
    if (!result.error.isEmpty()) {
        emit decodeFailed(result.error);
        return false;
    }

    handleDecodedText(result.text);
    emit decodeSucceeded(result.text);
    return true;
}

void QrDecoder::decodeImageFile(const QUrl& imageUrl)
{
    if (m_busy || !imageUrl.isValid())
        return;

    setBusy(true);
    auto* watcher = new QFutureWatcher<DecodeResult>(this);
    connect(watcher, &QFutureWatcher<DecodeResult>::finished, this, [this, watcher]() {
        const DecodeResult result = watcher->result();
        watcher->deleteLater();
        finishDecode(result.text, result.error, true);
    });
    watcher->setFuture(QtConcurrent::run([imageUrl]() {
        return decodeQrImage(loadImage(imageUrl), true);
    }));
}

void QrDecoder::setVideoSink(QObject* videoSink)
{
    if (m_frameConnection)
        disconnect(m_frameConnection);

    m_videoSink = qobject_cast<QVideoSink*>(videoSink);
    m_frameTimer.invalidate();
    if (!m_videoSink)
        return;

    m_frameConnection = connect(m_videoSink, &QVideoSink::videoFrameChanged,
                                this, [this](const QVideoFrame& frame) {
        if (m_busy || !frame.isValid())
            return;
        if (m_frameTimer.isValid() && m_frameTimer.elapsed() < kFrameIntervalMs)
            return;
        m_frameTimer.restart();
        startDecodeFrame(frame, false, kMaxVideoFrameDimension);
    });
}

bool QrDecoder::busy() const
{
    return m_busy;
}

void QrDecoder::startDecode(const QImage& image, bool reportFailure, int maxDimension)
{
    setBusy(true);
    auto* watcher = new QFutureWatcher<DecodeResult>(this);
    connect(watcher, &QFutureWatcher<DecodeResult>::finished, this,
            [this, watcher, reportFailure]() {
        const DecodeResult result = watcher->result();
        watcher->deleteLater();
        finishDecode(result.text, result.error, reportFailure);
    });
    watcher->setFuture(QtConcurrent::run([image, maxDimension]() {
        return decodeQrImage(scaledForDecode(image, maxDimension), true);
    }));
}

void QrDecoder::startDecodeFrame(const QVideoFrame& frame, bool reportFailure, int maxDimension)
{
    setBusy(true);
    auto* watcher = new QFutureWatcher<DecodeResult>(this);
    connect(watcher, &QFutureWatcher<DecodeResult>::finished, this,
            [this, watcher, reportFailure]() {
        const DecodeResult result = watcher->result();
        watcher->deleteLater();
        finishDecode(result.text, result.error, reportFailure);
    });
    // Frame conversion and scaling happen on the worker thread so the camera
    // preview never stalls while a frame is prepared for decoding.
    watcher->setFuture(QtConcurrent::run([frame, maxDimension]() {
        // Non-const working copy: QVideoFrame::map()/unmap() are non-const.
        QVideoFrame working = frame;

        // Single-pass path: when the frame exposes a full-resolution 8-bit Y
        // plane, feed it to zxing directly instead of the YUV→RGB→gray double
        // conversion. The wrapped QImage shares the mapped frame buffer, so the
        // frame must stay mapped until decoding is done.
        if (hasDirectLumaPlane(working.pixelFormat()) && working.map(QVideoFrame::ReadOnly)) {
            const QImage luma(working.bits(0), working.width(), working.height(),
                              working.bytesPerLine(0), QImage::Format_Grayscale8);
            const QImage scaled = scaledForDecode(luma, maxDimension);
            const DecodeResult result = decodeLum(scaled.constBits(), scaled.width(),
                                                  scaled.height(), scaled.bytesPerLine(), false);
            working.unmap();
            return result;
        }

        // Fallback: convert the whole frame to an image and decode from there.
        const QImage image = working.toImage();
        if (image.isNull())
            return DecodeResult{};
        return decodeQrImage(scaledForDecode(image, maxDimension), false);
    }));
}

void QrDecoder::finishDecode(const QString& text, const QString& error, bool reportFailure)
{
    setBusy(false);
    if (!error.isEmpty()) {
        if (reportFailure)
            emit decodeFailed(error);
        return;
    }
    if (text.isEmpty())
        return;  // no QR code in this frame
    handleDecodedText(text);
    emit decodeSucceeded(text);
}

void QrDecoder::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}
