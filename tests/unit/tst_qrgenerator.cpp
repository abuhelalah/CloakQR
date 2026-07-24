#include <QtTest>
#include <QFutureWatcher>
#include <QSignalSpy>

#include "qrdata.h"
#include "qrencoder.h"
#include "qrgenerator.h"

class TestQrGenerator : public QObject
{
    Q_OBJECT

private slots:
    // QrData
    void qrData_validText();
    void qrData_emptyTextIsInvalid();
    void qrData_tooLongTextIsInvalid();
    void qrData_detectsNumericMode();
    void qrData_detectsAlphanumericMode();
    void qrData_detectsByteMode();
    void qrData_capacityByEccLevel_data();
    void qrData_capacityByEccLevel();

    // QrEncoder
    void encoder_encodesShortText();
    void encoder_rejectsInvalidData();
    void encoder_matrixWidthMatchesVersion();

    // QrGenerator - sync
    void generator_generateQrReturnsNonNullImage();
    void generator_generateQrIsWhiteOnEmptyInput();
    void generator_saveAndReloadImage();

    // QrGenerator - SVG
    void generator_svgContainsXmlDeclaration();
    void generator_svgContainsSvgTag();
    void generator_svgContainsWhiteBackground();
    void generator_svgContainsDarkModules();

    // QrGenerator - async
    void generator_asyncGenerationCompletesWithNonNullImage();
    void generator_concurrentGenerationsAllSucceed();
};

// ---------- QrData tests ----------

void TestQrGenerator::qrData_validText()
{
    const QrData d(QStringLiteral("hello"));
    QVERIFY(d.isValid());
    QVERIFY(d.errorString().isEmpty());
}

void TestQrGenerator::qrData_emptyTextIsInvalid()
{
    const QrData d(QStringLiteral(""));
    QVERIFY(!d.isValid());
    QVERIFY(!d.errorString().isEmpty());
}

void TestQrGenerator::qrData_tooLongTextIsInvalid()
{
    const QString huge(QrData::kMaxBytesHigh + 1, QChar('A'));
    const QrData d(huge, EccLevel::High);
    QVERIFY(!d.isValid());
    QVERIFY(d.errorString().contains("exceeds"));
}

void TestQrGenerator::qrData_detectsNumericMode()
{
    const QrData d(QStringLiteral("1234567890"));
    QCOMPARE(d.encodeMode(), QrEncodeMode::Numeric);
}

void TestQrGenerator::qrData_detectsAlphanumericMode()
{
    const QrData d(QStringLiteral("HELLO WORLD"));
    QCOMPARE(d.encodeMode(), QrEncodeMode::Alphanumeric);
}

void TestQrGenerator::qrData_detectsByteMode()
{
    const QrData d(QStringLiteral("hello world"));   // lowercase triggers byte
    QCOMPARE(d.encodeMode(), QrEncodeMode::Byte);
}

void TestQrGenerator::qrData_capacityByEccLevel_data()
{
    QTest::addColumn<int>("eccLevel");
    QTest::addColumn<int>("expectedCapacity");

    QTest::newRow("Low")      << 0 << QrData::kMaxBytesLow;
    QTest::newRow("Medium")   << 1 << QrData::kMaxBytesMedium;
    QTest::newRow("Quartile") << 2 << QrData::kMaxBytesQuartile;
    QTest::newRow("High")     << 3 << QrData::kMaxBytesHigh;
}

void TestQrGenerator::qrData_capacityByEccLevel()
{
    QFETCH(int, eccLevel);
    QFETCH(int, expectedCapacity);

    const QrData d(QStringLiteral("test"), static_cast<EccLevel>(eccLevel));
    QCOMPARE(d.capacityBytes(), expectedCapacity);
}

// ---------- QrEncoder tests ----------

void TestQrGenerator::encoder_encodesShortText()
{
    QrEncoder encoder;
    const QrModuleMatrix m = encoder.encode(QStringLiteral("https://example.com"));
    QVERIFY(m.version > 0);
    QVERIFY(m.width > 0);
    QCOMPARE(m.modules.size(), m.width * m.width);
}

void TestQrGenerator::encoder_rejectsInvalidData()
{
    QrEncoder encoder;
    const QrModuleMatrix m = encoder.encode(QrData(QStringLiteral("")));
    QCOMPARE(m.version, 0);
}

void TestQrGenerator::encoder_matrixWidthMatchesVersion()
{
    QrEncoder encoder;
    const QrModuleMatrix m = encoder.encode(QStringLiteral("CloakQR"));
    QVERIFY(m.version >= 1 && m.version <= 40);
    QCOMPARE(m.width, (m.version - 1) * 4 + 21);
}

// ---------- QrGenerator sync tests ----------

void TestQrGenerator::generator_generateQrReturnsNonNullImage()
{
    QrGenerator gen;
    const QImage img = gen.generateQr(QStringLiteral("https://cloakqr.example"));
    QVERIFY(!img.isNull());
    QVERIFY(img.width() > 0);
    QVERIFY(img.height() > 0);
}

void TestQrGenerator::generator_generateQrIsWhiteOnEmptyInput()
{
    QrGenerator gen;
    const QImage img = gen.generateQr(QStringLiteral(""));
    // Empty text → encoder fails → white placeholder returned
    QVERIFY(!img.isNull());
    // Top-left pixel should be white
    QCOMPARE(img.pixel(0, 0), QColor(Qt::white).rgb());
}

void TestQrGenerator::generator_saveAndReloadImage()
{
    QTemporaryDir tmp;
    QVERIFY(tmp.isValid());
    const QUrl path = QUrl::fromLocalFile(tmp.filePath(QStringLiteral("out.png")));

    QrGenerator gen;
    const QImage img = gen.generateQr(QStringLiteral("save-test"));
    QVERIFY(gen.saveImage(img, path));

    const QImage reloaded(path.toLocalFile());
    QVERIFY(!reloaded.isNull());
    QCOMPARE(reloaded.size(), img.size());
}

// ---------- SVG tests ----------

void TestQrGenerator::generator_svgContainsXmlDeclaration()
{
    QrEncoder enc;
    const QrModuleMatrix m = enc.encode(QStringLiteral("SVG test"));
    QVERIFY(m.version > 0);
    const QString svg = QrGenerator::renderSvg(m);
    QVERIFY(svg.contains(QStringLiteral("<?xml")));
}

void TestQrGenerator::generator_svgContainsSvgTag()
{
    QrEncoder enc;
    const QrModuleMatrix m = enc.encode(QStringLiteral("SVG tag"));
    const QString svg = QrGenerator::renderSvg(m);
    QVERIFY(svg.contains(QStringLiteral("<svg")));
    QVERIFY(svg.contains(QStringLiteral("</svg>")));
}

void TestQrGenerator::generator_svgContainsWhiteBackground()
{
    QrEncoder enc;
    const QrModuleMatrix m = enc.encode(QStringLiteral("background"));
    const QString svg = QrGenerator::renderSvg(m);
    QVERIFY(svg.contains(QStringLiteral("#ffffff")));
}

void TestQrGenerator::generator_svgContainsDarkModules()
{
    QrEncoder enc;
    const QrModuleMatrix m = enc.encode(QStringLiteral("dark modules"));
    const QString svg = QrGenerator::renderSvg(m);
    QVERIFY(svg.contains(QStringLiteral("#000000")));
}

// ---------- Async tests ----------

void TestQrGenerator::generator_asyncGenerationCompletesWithNonNullImage()
{
    QrGenerator gen;
    QFutureWatcher<QImage> watcher;
    QSignalSpy spy(&watcher, &QFutureWatcher<QImage>::finished);

    watcher.setFuture(gen.generateQrAsync(QStringLiteral("async test")));
    QVERIFY(spy.wait(10000));   // up to 10 s

    const QImage img = watcher.result();
    QVERIFY(!img.isNull());
}

void TestQrGenerator::generator_concurrentGenerationsAllSucceed()
{
    QrGenerator gen;
    constexpr int kCount = 8;

    QVector<QFutureWatcher<QImage>*> watchers;
    watchers.reserve(kCount);

    for (int i = 0; i < kCount; ++i) {
        auto* w = new QFutureWatcher<QImage>(this);
        watchers.append(w);
        w->setFuture(gen.generateQrAsync(QStringLiteral("concurrent-%1").arg(i)));
    }

    for (auto* w : watchers) {
        w->waitForFinished();
        QVERIFY(!w->result().isNull());
    }
}

QTEST_MAIN(TestQrGenerator)
#include "tst_qrgenerator.moc"

