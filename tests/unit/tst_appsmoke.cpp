#include <QDir>
#include <QProcess>
#include <QProcessEnvironment>
#include <QSettings>
#include <QTemporaryDir>
#include <QtTest>

class tst_appsmoke : public QObject
{
    Q_OBJECT

private slots:
    void starts_data();
    void starts();
};

void tst_appsmoke::starts_data()
{
    QTest::addColumn<QString>("language");
    QTest::newRow("English LTR") << QStringLiteral("en");
    QTest::newRow("Arabic RTL") << QStringLiteral("ar");
}

void tst_appsmoke::starts()
{
    QFETCH(QString, language);
    QTemporaryDir home;
    QVERIFY(home.isValid());
    const QString settingsDir = home.filePath(QStringLiteral("CloakQR"));
    QVERIFY(QDir().mkpath(settingsDir));
    QSettings settings(settingsDir + QStringLiteral("/CloakQR.conf"), QSettings::IniFormat);
    settings.setValue(QStringLiteral("language"), language);
    settings.sync();

    QProcess process;
    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("XDG_CONFIG_HOME"), home.path());
    environment.insert(QStringLiteral("XDG_DATA_HOME"), home.filePath(QStringLiteral("data")));
    process.setProcessEnvironment(environment);
    process.start(QStringLiteral(CLOAKQR_APP_EXECUTABLE));
    QVERIFY(process.waitForStarted(5000));
    QTest::qWait(1500);
    QCOMPARE(process.state(), QProcess::Running);
    process.terminate();
    if (!process.waitForFinished(3000)) {
        process.kill();
        QVERIFY(process.waitForFinished(3000));
    }
    const QByteArray errors = process.readAllStandardError();
    QVERIFY2(!errors.contains("QQmlApplicationEngine failed"), errors.constData());
    QVERIFY2(!errors.contains("ReferenceError"), errors.constData());
    QVERIFY2(!errors.contains("Binding loop"), errors.constData());
}

QTEST_GUILESS_MAIN(tst_appsmoke)
#include "tst_appsmoke.moc"