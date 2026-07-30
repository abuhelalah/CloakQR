#include <QSignalSpy>
#include <QTemporaryDir>
#include <QVideoFrame>
#include <QVideoSink>
#include <QtTest>

#include "qrdecoder.h"
#include "qrgenerator.h"

class TestQrDecoder : public QObject
{
    Q_OBJECT

private slots:
    void classifiesPlainTextAsText();
    void decodesGeneratedImage();
    void decodesImageFileAsynchronously();
    void decodesVideoSinkFrame();
    void rejectsImageWithoutCode();
};

void TestQrDecoder::classifiesPlainTextAsText()
{
    QrDecoder decoder;
    QSignalSpy textSpy(&decoder, &QrDecoder::textDetected);
    QSignalSpy urlSpy(&decoder, &QrDecoder::urlDetected);

    decoder.handleDecodedText(QStringLiteral("Hello"));

    QCOMPARE(textSpy.count(), 1);
    QCOMPARE(textSpy.first().first().toString(), QStringLiteral("Hello"));
    QCOMPARE(urlSpy.count(), 0);
}

void TestQrDecoder::decodesGeneratedImage()
{
    const QString payload = QStringLiteral("https://example.com/private");
    QrGenerator generator;
    QrDecoder decoder;
    QSignalSpy urlSpy(&decoder, &QrDecoder::urlDetected);

    const QImage image = generator.generateQr(payload, 2, 640);
    QVERIFY(decoder.decodeImage(image));
    QCOMPARE(urlSpy.count(), 1);
    QCOMPARE(urlSpy.first().first().toString(), payload);
}

void TestQrDecoder::rejectsImageWithoutCode()
{
    QrDecoder decoder;
    QSignalSpy failureSpy(&decoder, &QrDecoder::decodeFailed);
    QImage image(320, 320, QImage::Format_RGB32);
    image.fill(Qt::white);

    QVERIFY(!decoder.decodeImage(image));
    QCOMPARE(failureSpy.count(), 1);
}

void TestQrDecoder::decodesImageFileAsynchronously()
{
    QTemporaryDir directory;
    QVERIFY(directory.isValid());
    const QString path = directory.filePath(QStringLiteral("selected.png"));
    const QString payload = QStringLiteral("image picker payload");

    QrGenerator generator;
    QVERIFY(generator.generateQr(payload, 1, 2560).save(path));

    QrDecoder decoder;
    QSignalSpy successSpy(&decoder, &QrDecoder::decodeSucceeded);
    QSignalSpy busySpy(&decoder, &QrDecoder::busyChanged);
    decoder.decodeImageFile(QUrl::fromLocalFile(path));

    QVERIFY(decoder.busy());
    QVERIFY(successSpy.wait(5000));
    QCOMPARE(successSpy.first().first().toString(), payload);
    QVERIFY(!decoder.busy());
    QCOMPARE(busySpy.count(), 2);
}

void TestQrDecoder::decodesVideoSinkFrame()
{
    const QString payload = QStringLiteral("live camera payload");
    QrGenerator generator;
    QVideoSink sink;
    QrDecoder decoder;
    QSignalSpy successSpy(&decoder, &QrDecoder::decodeSucceeded);
    decoder.setVideoSink(&sink);

    sink.setVideoFrame(QVideoFrame(generator.generateQr(payload, 1, 1920)));

    QVERIFY(successSpy.wait(5000));
    QCOMPARE(successSpy.first().first().toString(), payload);
    decoder.setVideoSink(nullptr);
}

QTEST_GUILESS_MAIN(TestQrDecoder)
#include "tst_qrdecoder.moc"