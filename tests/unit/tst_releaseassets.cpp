#include <QDir>
#include <QFile>
#include <QImage>
#include <QProcess>
#include <QRegularExpression>
#include <QTemporaryDir>
#include <QXmlStreamReader>
#include <QtTest>

class tst_releaseassets : public QObject
{
    Q_OBJECT

    static QString readText(const QString& path)
    {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            return QString();
        return QString::fromUtf8(file.readAll());
    }

private slots:
    void translationCatalogs_data();
    void translationCatalogs();
    void androidIdentityAndIcons();
    void linuxMetadata();
};

void tst_releaseassets::translationCatalogs_data()
{
    QTest::addColumn<QString>("locale");
    QTest::newRow("English") << QStringLiteral("en");
    QTest::newRow("Spanish") << QStringLiteral("es");
    QTest::newRow("French") << QStringLiteral("fr");
    QTest::newRow("Arabic") << QStringLiteral("ar");
}

void tst_releaseassets::translationCatalogs()
{
    QFETCH(QString, locale);
    const QString path = QStringLiteral(CLOAKQR_SOURCE_DIR "/resources/i18n/%1.ts").arg(locale);
    QFile file(path);
    QVERIFY2(file.open(QIODevice::ReadOnly | QIODevice::Text), qPrintable(path));

    QXmlStreamReader xml(&file);
    int messages = 0;
    while (!xml.atEnd()) {
        xml.readNext();
        if (!xml.isStartElement() || xml.name() != QLatin1String("message"))
            continue;

        ++messages;
        QString source;
        QString translation;
        bool unfinished = false;
        while (!(xml.isEndElement() && xml.name() == QLatin1String("message")) && !xml.atEnd()) {
            xml.readNext();
            if (!xml.isStartElement())
                continue;
            if (xml.name() == QLatin1String("source"))
                source = xml.readElementText();
            else if (xml.name() == QLatin1String("translation")) {
                unfinished = xml.attributes().value(QStringLiteral("type")) == QLatin1String("unfinished");
                translation = xml.readElementText();
            }
        }

        QVERIFY2(!unfinished, qPrintable(source));
        QVERIFY2(!translation.isEmpty(), qPrintable(source));
        const QRegularExpression placeholders(QStringLiteral("%[1-9]"));
        QStringList sourceArgs;
        QStringList translationArgs;
        auto sourceMatches = placeholders.globalMatch(source);
        while (sourceMatches.hasNext())
            sourceArgs.append(sourceMatches.next().captured());
        auto translationMatches = placeholders.globalMatch(translation);
        while (translationMatches.hasNext())
            translationArgs.append(translationMatches.next().captured());
        sourceArgs.sort();
        translationArgs.sort();
        QCOMPARE(translationArgs, sourceArgs);
    }
    QVERIFY2(!xml.hasError(), qPrintable(xml.errorString()));
    QVERIFY(messages >= 100);

    QTemporaryDir output;
    QVERIFY(output.isValid());
    QProcess lrelease;
    lrelease.start(QStringLiteral(CLOAKQR_LRELEASE_EXECUTABLE),
                   {path, QStringLiteral("-qm"), output.filePath(locale + QStringLiteral(".qm"))});
    QVERIFY(lrelease.waitForFinished(10000));
    QCOMPARE(lrelease.exitCode(), 0);
}

void tst_releaseassets::androidIdentityAndIcons()
{
    const QString imageRoot = QStringLiteral(CLOAKQR_SOURCE_DIR "/resources/images/");
    const QImage masterIcon(imageRoot + QStringLiteral("Logo_QR.png"));
    QVERIFY(!masterIcon.isNull());
    QCOMPARE(masterIcon.size(), QSize(1024, 1024));
    const QImage compactIcon(imageRoot + QStringLiteral("Logo_QR_icon.png"));
    QVERIFY(!compactIcon.isNull());
    QCOMPARE(compactIcon.size(), QSize(1024, 1024));
    const QImage siteIcon(QStringLiteral(CLOAKQR_SOURCE_DIR "/docs/logo.png"));
    QCOMPARE(siteIcon, compactIcon);
    QVERIFY(QFile::exists(imageRoot + QStringLiteral("Logo_QR.xcf")));
    QVERIFY(QFile::exists(QStringLiteral(CLOAKQR_SOURCE_DIR "/deploy/windows/cloakqr.ico")));

    const QString manifest = readText(QStringLiteral(CLOAKQR_SOURCE_DIR "/deploy/android/AndroidManifest.xml"));
    QVERIFY(manifest.contains(QStringLiteral("android:allowBackup=\"false\"")));
    QVERIFY(manifest.contains(QStringLiteral("android:usesCleartextTraffic=\"false\"")));
    QVERIFY(manifest.contains(QStringLiteral("android.permission.CAMERA")));
    const QStringList removedPermissions = {
        QStringLiteral("android.permission.INTERNET"),
        QStringLiteral("android.permission.ACCESS_NETWORK_STATE"),
        QStringLiteral("android.permission.BLUETOOTH"),
        QStringLiteral("android.permission.MODIFY_AUDIO_SETTINGS"),
        QStringLiteral("android.permission.RECORD_AUDIO"),
        QStringLiteral("android.permission.WRITE_EXTERNAL_STORAGE")
    };
    for (const QString& permission : removedPermissions) {
        const QRegularExpression removal(QStringLiteral("name=\\\"%1\\\" tools:node=\\\"remove\\\"")
                                             .arg(QRegularExpression::escape(permission)));
        QVERIFY2(removal.match(manifest).hasMatch(), qPrintable(permission));
    }
    const QString cmake = readText(QStringLiteral(CLOAKQR_SOURCE_DIR "/CMakeLists.txt"));
    QVERIFY(cmake.contains(QStringLiteral("com.abuhelalah.cloakqr.pro")));
    QVERIFY(cmake.contains(QStringLiteral("QT_ANDROID_PACKAGE_NAME \"${CLOAKQR_ANDROID_PACKAGE_NAME}\"")));
    QVERIFY(cmake.contains(QStringLiteral("QT_ANDROID_APP_NAME \"${CLOAKQR_PRODUCT_NAME}\"")));

    const QMap<QString, int> densities = {
        {QStringLiteral("mdpi"), 48}, {QStringLiteral("hdpi"), 72},
        {QStringLiteral("xhdpi"), 96}, {QStringLiteral("xxhdpi"), 144},
        {QStringLiteral("xxxhdpi"), 192}
    };
    for (auto it = densities.cbegin(); it != densities.cend(); ++it) {
        const QString directory = QStringLiteral(CLOAKQR_SOURCE_DIR "/deploy/android/res/mipmap-%1/").arg(it.key());
        for (const QString& fileName : {QStringLiteral("ic_launcher.png"),
                                        QStringLiteral("ic_launcher_round.png")}) {
            const QString iconPath = directory + fileName;
            const QImage icon(iconPath);
            QVERIFY2(!icon.isNull(), qPrintable(iconPath));
            QCOMPARE(icon.size(), QSize(it.value(), it.value()));
        }
    }
}

void tst_releaseassets::linuxMetadata()
{
    const QString desktop = readText(QStringLiteral(CLOAKQR_SOURCE_DIR "/deploy/linux/com.abuhelalah.cloakqr.desktop"));
    QVERIFY(desktop.startsWith(QStringLiteral("[Desktop Entry]")));
    QVERIFY(desktop.contains(QStringLiteral("Exec=cloakqr")));
    QVERIFY(desktop.contains(QStringLiteral("Icon=com.abuhelalah.cloakqr")));

    QFile metadata(QStringLiteral(CLOAKQR_SOURCE_DIR "/deploy/linux/com.abuhelalah.cloakqr.metainfo.xml"));
    QVERIFY(metadata.open(QIODevice::ReadOnly | QIODevice::Text));
    QXmlStreamReader xml(&metadata);
    while (!xml.atEnd())
        xml.readNext();
    QVERIFY2(!xml.hasError(), qPrintable(xml.errorString()));
}

QTEST_GUILESS_MAIN(tst_releaseassets)
#include "tst_releaseassets.moc"