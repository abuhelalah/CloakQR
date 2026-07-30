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

DecodeResult decodeQrImage(const QImage& image)
{
    if (image.isNull())
        return {{}, QrDecoder::tr("The selected image could not be opened.")};

    const QImage grayscale = image.convertToFormat(QImage::Format_Grayscale8);
    const ZXing::ImageView imageView(grayscale.constBits(), grayscale.width(), grayscale.height(),
                                     ZXing::ImageFormat::Lum, grayscale.bytesPerLine());
    const ZXing::DecodeHints options = ZXing::DecodeHints()
        .setFormats(ZXing::BarcodeFormat::QRCode)
        .setTryHarder(true)
        .setTryRotate(true);
    const ZXing::Result result = ZXing::ReadBarcode(imageView, options);
    if (!result.isValid())
        return {{}, QrDecoder::tr("No QR code was found in the image.")};

    const QByteArray bytes = QByteArray::fromStdString(result.text());
    const QString text = QString::fromUtf8(bytes);
    if (text.toUtf8() != bytes)
        return {{}, QrDecoder::tr("The QR code does not contain valid UTF-8 text.")};

    return {text, {}};
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
    const QByteArray data = file.read(kMaxImageBytes + 1);
    if (data.size() > kMaxImageBytes)
        return {};

    QBuffer buffer;
    buffer.setData(data);
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
    const DecodeResult result = decodeQrImage(image);
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
        return decodeQrImage(loadImage(imageUrl));
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
        const QImage image = frame.toImage();
        if (!image.isNull())
            startDecode(image, false, kMaxVideoFrameDimension);
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
        return decodeQrImage(scaledForDecode(image, maxDimension));
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
