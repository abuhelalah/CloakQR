#pragma once

#include <QObject>
#include <QString>

// Bridges QML to platform-specific capabilities. On Android it hands a scanned
// Wi-Fi network to the system so the user can confirm and connect. On other
// platforms the Wi-Fi actions are reported as unsupported.
class PlatformBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool wifiConnectSupported READ wifiConnectSupported CONSTANT)
    Q_PROPERTY(bool contactInsertSupported READ contactInsertSupported CONSTANT)
    Q_PROPERTY(bool calendarInsertSupported READ calendarInsertSupported CONSTANT)

public:
    explicit PlatformBridge(QObject* parent = nullptr);
    ~PlatformBridge() override;

    bool wifiConnectSupported() const;
    bool contactInsertSupported() const;
    bool calendarInsertSupported() const;

    // Asks the operating system to add/connect to the given Wi-Fi network,
    // showing a native confirmation prompt. Returns true when the request was
    // handed off to the OS.
    Q_INVOKABLE bool connectToWifi(const QString& ssid,
                                   const QString& password,
                                   const QString& security,
                                   bool hidden);

    // Opens the system "new contact" screen pre-filled with the given details
    // (Android only). Returns true when the request was handed to the OS.
    Q_INVOKABLE bool addContact(const QString& name,
                                const QString& phone,
                                const QString& email);

    // Opens the system calendar's "new event" screen pre-filled from a parsed
    // iCalendar entry (Android only). Returns true when the request was handed
    // to the OS. startMillis/endMillis are epoch milliseconds (0 = omitted).
    Q_INVOKABLE bool addCalendarEvent(const QString& title,
                                      const QString& description,
                                      const QString& location,
                                      qint64 startMillis,
                                      qint64 endMillis);

    // Opens the desktop's email client with a pre-filled draft, preferring a
    // real mail application over a browser-based mailto handler. Returns false
    // when no desktop handling was attempted so the caller can fall back to the
    // generic mailto: URL (e.g. on mobile).
    Q_INVOKABLE bool composeEmail(const QString& address,
                                  const QString& subject,
                                  const QString& body);

    // Shares a local file (e.g. a generated QR PNG) via the Android share
    // sheet using the app's FileProvider authority. Returns true when the
    // intent was handed off; false otherwise (and always false off-Android).
    Q_INVOKABLE bool shareFile(const QString& path);

    // Reports whether the device can authenticate with biometrics (fingerprint
    // or face). Always false off-Android.
    Q_INVOKABLE bool isBiometricAvailable();

    // Shows the system BiometricPrompt to unlock the app (Android only; no-op
    // elsewhere). The result is delivered via biometricAuthenticated().
    Q_INVOKABLE void authenticate();

signals:
    // Emitted with true when biometric authentication succeeded, false when it
    // failed or was cancelled.
    void biometricAuthenticated(bool success);

private:
#ifdef Q_OS_ANDROID
    void registerNativeMethods();
#endif
};
