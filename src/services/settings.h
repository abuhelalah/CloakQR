#pragma once

#include <QObject>
#include <QSettings>
#include <QString>

// Persistent application settings backed by QSettings.
//
// Exposes the keys defined in the development plan (theme, language, history
// privacy, save/export directories, upgrade pop-up scheduling and the paid
// activation token) as QML-friendly properties, plus a derived darkMode flag
// that resolves the "system" theme against the platform colour scheme.
class Settings : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)
    Q_PROPERTY(bool darkMode READ darkMode NOTIFY darkModeChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(bool highContrast READ highContrast WRITE setHighContrast NOTIFY highContrastChanged)
    Q_PROPERTY(qreal fontScale READ fontScale WRITE setFontScale NOTIFY fontScaleChanged)
    Q_PROPERTY(bool historyEnabled READ historyEnabled WRITE setHistoryEnabled NOTIFY historyEnabledChanged)
    Q_PROPERTY(bool historyExcludeWifiPassword READ historyExcludeWifiPassword
                   WRITE setHistoryExcludeWifiPassword NOTIFY historyExcludeWifiPasswordChanged)
    Q_PROPERTY(QString defaultSaveDirectory READ defaultSaveDirectory
                   WRITE setDefaultSaveDirectory NOTIFY defaultSaveDirectoryChanged)
    Q_PROPERTY(QString recentExportDirectory READ recentExportDirectory
                   WRITE setRecentExportDirectory NOTIFY recentExportDirectoryChanged)

public:
    explicit Settings(QObject* parent = nullptr);

    QString theme() const;                 // "system" | "light" | "dark"
    void setTheme(const QString& value);

    bool darkMode() const;                 // resolved dark/light flag

    QString language() const;              // "system" | "en" | "es" | "fr" | "ar"
    void setLanguage(const QString& value);

    bool highContrast() const;
    void setHighContrast(bool value);

    qreal fontScale() const;               // 0.8 .. 2.0
    void setFontScale(qreal value);

    bool historyEnabled() const;
    void setHistoryEnabled(bool value);

    bool historyExcludeWifiPassword() const;
    void setHistoryExcludeWifiPassword(bool value);

    QString defaultSaveDirectory() const;
    void setDefaultSaveDirectory(const QString& value);

    QString recentExportDirectory() const;
    void setRecentExportDirectory(const QString& value);

    // Non-property keys used by other subsystems.
    QString lastPopupDate() const;
    void setLastPopupDate(const QString& isoDate);

    Q_INVOKABLE void resetToDefaults();

signals:
    void themeChanged();
    void darkModeChanged();
    void languageChanged();
    void highContrastChanged();
    void fontScaleChanged();
    void historyEnabledChanged();
    void historyExcludeWifiPasswordChanged();
    void defaultSaveDirectoryChanged();
    void recentExportDirectoryChanged();

private:
    void connectColorSchemeSignal();

    QSettings m_store;
};
