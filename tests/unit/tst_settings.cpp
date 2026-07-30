#include "settings.h"

#include <QSignalSpy>
#include <QStandardPaths>
#include <QtTest>

class tst_settings : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void init();

    void defaults();
    void themeResolvesDarkMode();
    void fontScaleIsClamped();
    void valuesPersist();
    void resetRestoresDefaults();
    void languageEmitsSignal();
};

void tst_settings::initTestCase()
{
    // Route QSettings to a throwaway location so tests never touch real config.
    QStandardPaths::setTestModeEnabled(true);
    QCoreApplication::setOrganizationName(QStringLiteral("CloakQRTest"));
    QCoreApplication::setApplicationName(QStringLiteral("SettingsTest"));
}

void tst_settings::init()
{
    // Start every test from a clean store.
    Settings().resetToDefaults();
}

void tst_settings::defaults()
{
    Settings s;
    QCOMPARE(s.theme(), QStringLiteral("system"));
    QCOMPARE(s.language(), QStringLiteral("system"));
    QCOMPARE(s.highContrast(), false);
    QCOMPARE(s.fontScale(), 1.0);
    QCOMPARE(s.historyEnabled(), true);
    QCOMPARE(s.historyExcludeWifiPassword(), true);
}

void tst_settings::themeResolvesDarkMode()
{
    Settings s;
    s.setTheme(QStringLiteral("dark"));
    QCOMPARE(s.darkMode(), true);
    s.setTheme(QStringLiteral("light"));
    QCOMPARE(s.darkMode(), false);
}

void tst_settings::fontScaleIsClamped()
{
    Settings s;
    s.setFontScale(5.0);
    QCOMPARE(s.fontScale(), 2.0);
    s.setFontScale(0.1);
    QCOMPARE(s.fontScale(), 0.8);
}

void tst_settings::valuesPersist()
{
    {
        Settings s;
        s.setHistoryEnabled(false);
        s.setLanguage(QStringLiteral("ar"));
        s.setFontScale(1.5);
    }
    Settings reopened;
    QCOMPARE(reopened.historyEnabled(), false);
    QCOMPARE(reopened.language(), QStringLiteral("ar"));
    QCOMPARE(reopened.fontScale(), 1.5);
}

void tst_settings::resetRestoresDefaults()
{
    Settings s;
    s.setHighContrast(true);
    s.setLanguage(QStringLiteral("fr"));
    s.resetToDefaults();
    QCOMPARE(s.highContrast(), false);
    QCOMPARE(s.language(), QStringLiteral("system"));
}

void tst_settings::languageEmitsSignal()
{
    Settings s;
    QSignalSpy spy(&s, &Settings::languageChanged);
    s.setLanguage(QStringLiteral("es"));
    QCOMPARE(spy.count(), 1);
    // Setting the same value again should not re-emit.
    s.setLanguage(QStringLiteral("es"));
    QCOMPARE(spy.count(), 1);
}

QTEST_MAIN(tst_settings)
#include "tst_settings.moc"
