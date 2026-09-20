#pragma once

#include <QAtomicInt>
#include <QColor>
#include <QImage>
#include <QQuickImageProvider>

class QrGenerator;

// Asynchronous image response for the "image://qrcode/" provider. It renders
// the QR code on a worker thread and hands the finished image back to QML via
// the QQuickImageResponse::finished() signal, so the UI thread never blocks on
// QR generation (e.g. the Generator preview at 1024px).
class QrImageResponse : public QQuickImageResponse
{
public:
    QrImageResponse(const QString& text, int ecc, int targetSize,
                    const QColor& foreground, const QColor& background,
                    QrGenerator* generator);

    QString errorString() const override;
    QQuickTextureFactory* textureFactory() const override;
    void cancel() override;

private:
    QImage m_image;
    QString m_error;
    QAtomicInt m_cancelled;
};

// Serves generated QR images to QML. The synchronous requestImage() path is
// kept for any non-async consumers; Image elements with asynchronous: true
// use requestImageResponse() instead.
class QrImageProvider : public QQuickAsyncImageProvider
{
public:
    explicit QrImageProvider(QrGenerator* generator);

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;
    QQuickImageResponse* requestImageResponse(const QString& id, const QSize& requestedSize) override;

private:
    QrGenerator* m_generator;
};
