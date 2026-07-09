#include <QtTest>

#include "cryptohelper.h"

class TestCryptoHelper : public QObject
{
    Q_OBJECT

private slots:
    void encryptRoundTrip();
    void rejectWrongPassphrase();
    void rejectTamperedPayload();
    void rejectMalformedPayload_data();
    void rejectMalformedPayload();
};

void TestCryptoHelper::encryptRoundTrip()
{
    CryptoHelper helper;

    const QString payload = helper.encryptText(QStringLiteral("hello cloakqr"), QStringLiteral("correct horse battery staple"));
    const QStringList parts = payload.split(':');

    QVERIFY(payload.startsWith(QStringLiteral("ENC:1:")));
    QCOMPARE(parts.size(), 8);
    QCOMPARE(parts[2], QStringLiteral("pbkdf2-sha256"));
    QVERIFY(parts[3].toInt() > 0);
    QCOMPARE(helper.decryptText(payload, QStringLiteral("correct horse battery staple")), QStringLiteral("hello cloakqr"));
}

void TestCryptoHelper::rejectWrongPassphrase()
{
    CryptoHelper helper;

    const QString payload = helper.encryptText(QStringLiteral("secret"), QStringLiteral("passphrase-one"));

    QVERIFY(!payload.isEmpty());
    QVERIFY(helper.decryptText(payload, QStringLiteral("passphrase-two")).isEmpty());
}

void TestCryptoHelper::rejectTamperedPayload()
{
    CryptoHelper helper;

    const QString payload = helper.encryptText(QStringLiteral("secret"), QStringLiteral("passphrase-one"));
    QString tampered = payload;
    tampered[tampered.size() - 2] = tampered.endsWith('A') ? 'B' : 'A';

    QVERIFY(helper.decryptText(tampered, QStringLiteral("passphrase-one")).isEmpty());
}

void TestCryptoHelper::rejectMalformedPayload_data()
{
    QTest::addColumn<QString>("payload");

    QTest::newRow("not-enc") << QStringLiteral("plain text");
    QTest::newRow("wrong-version") << QStringLiteral("ENC:2:pbkdf2-sha256:200000:aaaa:bbbb:cccc:dddd");
    QTest::newRow("missing-field") << QStringLiteral("ENC:1:pbkdf2-sha256:200000:aaaa:bbbb:cccc");
    QTest::newRow("bad-iterations") << QStringLiteral("ENC:1:pbkdf2-sha256:abc:aaaa:bbbb:cccc:dddd");
    QTest::newRow("bad-base64") << QStringLiteral("ENC:1:pbkdf2-sha256:200000:not*base64:bbbb:cccc:dddd");
}

void TestCryptoHelper::rejectMalformedPayload()
{
    QFETCH(QString, payload);

    CryptoHelper helper;
    QVERIFY(helper.decryptText(payload, QStringLiteral("passphrase-one")).isEmpty());
}

QTEST_MAIN(TestCryptoHelper)
#include "tst_cryptohelper.moc"
