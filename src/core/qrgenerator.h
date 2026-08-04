#pragma once

#include <QColor>
#include <QImage>
#include <QObject>
#include <QUrl>
#include <QVariantMap>

// Generates QR code images and SVG documents from arbitrary text.
//
// Synchronous helpers are provided for the CLI and tests, while requestQr()
// performs generation on a worker thread (QtConcurrent) so the UI never blocks,
// emitting qrReady()/qrFailed() when finished.
class QrGenerator : public QObject
{
    Q_OBJECT

public:
    explicit QrGenerator(QObject* parent = nullptr);

    // eccLevel: 0 = Low, 1 = Medium, 2 = Quartile, 3 = High.
    Q_INVOKABLE QImage generateQr(const QString& text, int eccLevel = 1, int targetSize = 512,
                                  const QColor& foreground = QColor(Qt::black),
                                  const QColor& background = QColor(Qt::white)) const;

    Q_INVOKABLE QString generateSvg(const QString& text, int eccLevel = 1, int quietZone = 4,
                                    const QColor& foreground = QColor(Qt::black),
                                    const QColor& background = QColor(Qt::white)) const;

    // Smallest QR version required for the text, or -1 when it does not fit.
    Q_INVOKABLE int requiredVersion(const QString& text, int eccLevel = 1) const;

    // Asynchronously generates a QR image; emits qrReady() or qrFailed().
    Q_INVOKABLE void requestQr(const QString& text, int eccLevel = 1, int targetSize = 512,
                               const QColor& foreground = QColor(Qt::black),
                               const QColor& background = QColor(Qt::white));

    Q_INVOKABLE bool saveImage(const QImage& image, const QUrl& outputUrl) const;

    // Payload builders exposed to QML for the generator UI. Each returns the
    // canonical string that should be encoded for the given content type.
    Q_INVOKABLE QString textPayload(const QString& value) const;
    Q_INVOKABLE QString urlPayload(const QString& value) const;
    Q_INVOKABLE QString emailPayload(const QString& address, const QString& subject = QString(),
                                     const QString& body = QString()) const;
    Q_INVOKABLE QString phonePayload(const QString& number) const;
    Q_INVOKABLE QString smsPayload(const QString& number, const QString& message = QString()) const;
    Q_INVOKABLE QString wifiPayload(const QString& ssid, const QString& password,
                                    const QString& auth, bool hidden = false) const;
    Q_INVOKABLE QString geoPayload(double latitude, double longitude) const;
    Q_INVOKABLE QString geoPayload(double latitude, double longitude, const QString& label) const;
    Q_INVOKABLE QString vcardPayload(const QString& fullName, const QString& organization = QString(),
                                     const QString& phone = QString(), const QString& email = QString(),
                                     const QString& url = QString()) const;

    // Capacity report for a payload: { fits, version, maxBytes, usedBytes }.
    Q_INVOKABLE QVariantMap capacityInfo(const QString& payload, int eccLevel = 1) const;

signals:
    void qrReady(const QImage& image, const QString& text);
    void qrFailed(const QString& text, const QString& reason);
};
