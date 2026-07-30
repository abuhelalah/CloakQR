#include "settings.h"

#include <QGuiApplication>
#include <QStandardPaths>
#include <QStyleHints>

namespace {
constexpr auto kTheme = "theme";
constexpr auto kLanguage = "language";
constexpr auto kHighContrast = "highContrast";
constexpr auto kFontScale = "fontScale";
constexpr auto kHistoryEnabled = "historyEnabled";
constexpr auto kHistoryExcludeWifiPassword = "historyExcludeWiFiPassword";
constexpr auto kDefaultSaveDirectory = "defaultSaveDirectory";
constexpr auto kRecentExportDirectory = "recentExportDirectory";
constexpr auto kLastPopupDate = "lastPopupDate";
} // namespace

Settings::Settings(QObject* parent)
    : QObject(parent)
{
    connectColorSchemeSignal();
}

void Settings::connectColorSchemeSignal()
{
    if (auto* hints = QGuiApplication::styleHints()) {
        connect(hints, &QStyleHints::colorSchemeChanged, this, [this]() {
            if (theme() == QLatin1String("system"))
                emit darkModeChanged();
        });
    }
}

QString Settings::theme() const
{
    return m_store.value(kTheme, QStringLiteral("system")).toString();
}

void Settings::setTheme(const QString& value)
{
    if (theme() == value)
        return;
    m_store.setValue(kTheme, value);
    emit themeChanged();
    emit darkModeChanged();
}

bool Settings::darkMode() const
{
    const QString mode = theme();
    if (mode == QLatin1String("dark"))
        return true;
    if (mode == QLatin1String("light"))
        return false;
    if (auto* hints = QGuiApplication::styleHints())
        return hints->colorScheme() == Qt::ColorScheme::Dark;
    return false;
}

QString Settings::language() const
{
    return m_store.value(kLanguage, QStringLiteral("system")).toString();
}

void Settings::setLanguage(const QString& value)
{
    if (language() == value)
        return;
    m_store.setValue(kLanguage, value);
    emit languageChanged();
}

bool Settings::highContrast() const
{
    return m_store.value(kHighContrast, false).toBool();
}

void Settings::setHighContrast(bool value)
{
    if (highContrast() == value)
        return;
    m_store.setValue(kHighContrast, value);
    emit highContrastChanged();
}

qreal Settings::fontScale() const
{
    return m_store.value(kFontScale, 1.0).toReal();
}

void Settings::setFontScale(qreal value)
{
    const qreal clamped = qBound(0.8, value, 2.0);
    if (qFuzzyCompare(fontScale(), clamped))
        return;
    m_store.setValue(kFontScale, clamped);
    emit fontScaleChanged();
}

bool Settings::historyEnabled() const
{
    return m_store.value(kHistoryEnabled, true).toBool();
}

void Settings::setHistoryEnabled(bool value)
{
    if (historyEnabled() == value)
        return;
    m_store.setValue(kHistoryEnabled, value);
    emit historyEnabledChanged();
}

bool Settings::historyExcludeWifiPassword() const
{
    return m_store.value(kHistoryExcludeWifiPassword, true).toBool();
}

void Settings::setHistoryExcludeWifiPassword(bool value)
{
    if (historyExcludeWifiPassword() == value)
        return;
    m_store.setValue(kHistoryExcludeWifiPassword, value);
    emit historyExcludeWifiPasswordChanged();
}

QString Settings::defaultSaveDirectory() const
{
    const QString fallback =
        QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    return m_store.value(kDefaultSaveDirectory, fallback).toString();
}

void Settings::setDefaultSaveDirectory(const QString& value)
{
    if (defaultSaveDirectory() == value)
        return;
    m_store.setValue(kDefaultSaveDirectory, value);
    emit defaultSaveDirectoryChanged();
}

QString Settings::recentExportDirectory() const
{
    const QString fallback =
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    return m_store.value(kRecentExportDirectory, fallback).toString();
}

void Settings::setRecentExportDirectory(const QString& value)
{
    if (recentExportDirectory() == value)
        return;
    m_store.setValue(kRecentExportDirectory, value);
    emit recentExportDirectoryChanged();
}

QString Settings::lastPopupDate() const
{
    return m_store.value(kLastPopupDate).toString();
}

void Settings::setLastPopupDate(const QString& isoDate)
{
    m_store.setValue(kLastPopupDate, isoDate);
}

void Settings::resetToDefaults()
{
    m_store.clear();
    emit themeChanged();
    emit darkModeChanged();
    emit languageChanged();
    emit highContrastChanged();
    emit fontScaleChanged();
    emit historyEnabledChanged();
    emit historyExcludeWifiPasswordChanged();
    emit defaultSaveDirectoryChanged();
    emit recentExportDirectoryChanged();
}
