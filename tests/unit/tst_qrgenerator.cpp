#include <QtTest>
#include <QImage>
#include <QSignalSpy>
#include <QXmlStreamReader>

#include "qrdata.h"
#include "qrencoder.h"
#include "qrgenerator.h"

using cloakqr::QrCode;
using cloakqr::QrData;
using cloakqr::QrEcc;
using cloakqr::QrEncoder;

class TestQrGenerator : public QObject
{
    Q_OBJECT

private slots:
    // --- QrEncoder capacity ---------------------------------------------

    void byteCapacity_data()
    {
        QTest::addColumn<int>("version");
        QTest::addColumn<int>("ecc");
        QTest::addColumn<int>("expected");

        QTest::newRow("v1-L") << 1 << int(QrEcc::Low) << 17;
        QTest::newRow("v1-M") << 1 << int(QrEcc::Medium) << 14;
        QTest::newRow("v1-Q") << 1 << int(QrEcc::Quartile) << 11;
        QTest::newRow("v1-H") << 1 << int(QrEcc::High) << 7;
        QTest::newRow("v40-L") << 40 << int(QrEcc::Low) << 2953;
        QTest::newRow("v10-M") << 10 << int(QrEcc::Medium) << 213;
        QTest::newRow("v10-L") << 10 << int(QrEcc::Low) << 271;
    }

    void byteCapacity()
    {
        QFETCH(int, version);
        QFETCH(int, ecc);
        QFETCH(int, expected);
        QCOMPARE(QrEncoder::byteModeCapacity(version, QrEcc(ecc)), expected);
    }

    // --- Version selection ----------------------------------------------

    void minimumVersion_data()
    {
        QTest::addColumn<QString>("text");
        QTest::addColumn<int>("ecc");
        QTest::addColumn<int>("expected");

        // Lower-case letters force byte mode (17 bytes fit v1 at Low).
        QTest::newRow("17 bytes L") << QString(17, 'a') << int(QrEcc::Low) << 1;
        QTest::newRow("18 bytes L") << QString(18, 'a') << int(QrEcc::Low) << 2;
        QTest::newRow("empty") << QString() << int(QrEcc::Medium) << 1;
        // Too large for any version-40 symbol.
        QTest::newRow("overflow") << QString(6000, 'a') << int(QrEcc::Low) << -1;
    }

    void minimumVersion()
    {
        QFETCH(QString, text);
        QFETCH(int, ecc);
        QFETCH(int, expected);
        QCOMPARE(QrEncoder::minimumVersion(text, QrEcc(ecc)), expected);
    }

    void higherEccNeedsHigherVersion()
    {
        const QString text(200, 'a');
        const int low = QrEncoder::minimumVersion(text, QrEcc::Low);
        const int high = QrEncoder::minimumVersion(text, QrEcc::High);
        QVERIFY(low > 0);
        QVERIFY(high > 0);
        QVERIFY(high >= low);
    }

    // --- Structural validation ------------------------------------------

    void encodeProducesValidGeometry()
    {
        const QrCode code = QrEncoder::encodeText(QStringLiteral("HELLO WORLD"), QrEcc::Quartile);
        QVERIFY(code.isValid());
        QCOMPARE(code.size(), code.version() * 4 + 17);
    }

    void finderPatternsArePlaced()
    {
        const QrCode code = QrEncoder::encodeText(QStringLiteral("finder-check"), QrEcc::Medium);
        QVERIFY(code.isValid());
        const int n = code.size();

        const auto checkFinder = [&](int ox, int oy) {
            // Corners of the 7x7 finder are dark; the inner ring is light.
            QVERIFY(code.module(ox + 0, oy + 0));
            QVERIFY(code.module(ox + 6, oy + 0));
            QVERIFY(code.module(ox + 0, oy + 6));
            QVERIFY(code.module(ox + 3, oy + 3));
            QVERIFY(!code.module(ox + 1, oy + 1));
        };
        checkFinder(0, 0);
        checkFinder(n - 7, 0);
        checkFinder(0, n - 7);
    }

    void timingAndDarkModule()
    {
        const QrCode code = QrEncoder::encodeText(QStringLiteral("timing"), QrEcc::Medium);
        QVERIFY(code.isValid());
        const int n = code.size();

        // Timing pattern alternates on row/column 6 between the finders.
        for (int x = 8; x < n - 8; ++x)
            QCOMPARE(code.module(x, 6), (x % 2 == 0));

        // The always-dark module sits at (8, size - 8).
        QVERIFY(code.module(8, n - 8));
    }

    void identifiesFunctionModules()
    {
        const QrCode code = QrEncoder::encodeText(QStringLiteral("function-mask"), QrEcc::High);
        QVERIFY(code.isValid());
        QCOMPARE(code.functionModules().size(), code.size() * code.size());

        QVERIFY(code.isFunctionModule(0, 0));
        QVERIFY(code.isFunctionModule(6, 10));
        QVERIFY(code.isFunctionModule(8, code.size() - 8));
        QVERIFY(!code.isFunctionModule(-1, 0));

        int dataModuleCount = 0;
        for (int y = 0; y < code.size(); ++y)
            for (int x = 0; x < code.size(); ++x)
                if (!code.isFunctionModule(x, y))
                    ++dataModuleCount;
        QVERIFY(dataModuleCount > 0);
    }

    // --- SVG output ------------------------------------------------------

    void svgIsWellFormed()
    {
        QrGenerator generator;
        const QString svg = generator.generateSvg(QStringLiteral("https://cloakqr.app"));
        QVERIFY(svg.startsWith(QStringLiteral("<?xml")));
        QVERIFY(svg.contains(QStringLiteral("<path")));

        QXmlStreamReader reader(svg);
        while (!reader.atEnd())
            reader.readNext();
        QVERIFY2(!reader.hasError(), qPrintable(reader.errorString()));
    }

    void svgEmptyForOverflow()
    {
        QrGenerator generator;
        QVERIFY(generator.generateSvg(QString(6000, 'a')).isEmpty());
    }

    // --- Image output ----------------------------------------------------

    void generatesNonNullImage()
    {
        QrGenerator generator;
        const QImage image = generator.generateQr(QStringLiteral("https://example.com"));
        QVERIFY(!image.isNull());
        QCOMPARE(image.width(), image.height());
        QVERIFY(image.width() > 0);
    }

    void asyncEmitsReady()
    {
        QrGenerator generator;
        QSignalSpy readySpy(&generator, &QrGenerator::qrReady);
        generator.requestQr(QStringLiteral("async payload"));
        QVERIFY(readySpy.wait(5000));
        QCOMPARE(readySpy.count(), 1);
    }

    void asyncEmitsFailedForOverflow()
    {
        QrGenerator generator;
        QSignalSpy failedSpy(&generator, &QrGenerator::qrFailed);
        generator.requestQr(QString(6000, 'a'));
        QVERIFY(failedSpy.wait(5000));
        QCOMPARE(failedSpy.count(), 1);
    }

    // --- QrData payloads -------------------------------------------------

    void payloads_data()
    {
        QTest::addColumn<QString>("actual");
        QTest::addColumn<QString>("expected");

        QTest::newRow("url-bare")
            << QrData::url(QStringLiteral("example.com"))
            << QStringLiteral("https://example.com");
        QTest::newRow("url-scheme")
            << QrData::url(QStringLiteral("http://x.test"))
            << QStringLiteral("http://x.test");
        QTest::newRow("geo")
            << QrData::geo(1.5, 2.5)
            << QStringLiteral("geo:1.500000,2.500000");
        QTest::newRow("email")
            << QrData::email(QStringLiteral("a@b.com"), QStringLiteral("Hi there"))
            << QStringLiteral("mailto:a@b.com?subject=Hi%20there");
        QTest::newRow("wifi-escaped")
            << QrData::wifi(QStringLiteral("MyNet"), QStringLiteral("p;w"), QrData::WifiAuth::Wpa)
            << QStringLiteral("WIFI:S:MyNet;T:WPA;P:p\\;w;;");
        QTest::newRow("phone")
            << QrData::phone(QStringLiteral("+1 555 010"))
            << QStringLiteral("tel:+1555010");
    }

    void payloads()
    {
        QFETCH(QString, actual);
        QFETCH(QString, expected);
        QCOMPARE(actual, expected);
    }

    void capacityReportsFit()
    {
        const QrData::Capacity info = QrData::capacity(QStringLiteral("hello"), QrEcc::Medium);
        QVERIFY(info.fits);
        QCOMPARE(info.version, 1);
        QCOMPARE(info.usedBytes, 5);
        QVERIFY(info.maxBytes >= info.usedBytes);

        QVERIFY(!QrData::isValid(QString()));
        QVERIFY(QrData::isValid(QStringLiteral("payload")));
    }
};

QTEST_MAIN(TestQrGenerator)
#include "tst_qrgenerator.moc"
