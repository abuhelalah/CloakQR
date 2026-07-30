#pragma once

#include <QImage>
#include <QElapsedTimer>
#include <QObject>
#include <QPointer>
#include <QUrl>

class QVideoSink;

class QrDecoder : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit QrDecoder(QObject* parent = nullptr);

    Q_INVOKABLE void handleDecodedText(const QString& text);
    Q_INVOKABLE void decodeImageFile(const QUrl& imageUrl);
    Q_INVOKABLE void setVideoSink(QObject* videoSink);
    bool decodeImage(const QImage& image);
    bool busy() const;

signals:
    void urlDetected(const QString& url);
    void textDetected(const QString& text);
    void decodeSucceeded(const QString& text);
    void decodeFailed(const QString& reason);
    void busyChanged();

private:
    void finishDecode(const QString& text, const QString& error, bool reportFailure);
    void startDecode(const QImage& image, bool reportFailure, int maxDimension = 0);
    void setBusy(bool busy);

    bool m_busy = false;
    QPointer<QVideoSink> m_videoSink;
    QMetaObject::Connection m_frameConnection;
    QElapsedTimer m_frameTimer;
};
