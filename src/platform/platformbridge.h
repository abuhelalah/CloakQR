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

public:
    explicit PlatformBridge(QObject* parent = nullptr);

    bool wifiConnectSupported() const;
    bool contactInsertSupported() const;

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

    // Opens the desktop's email client with a pre-filled draft, preferring a
    // real mail application over a browser-based mailto handler. Returns false
    // when no desktop handling was attempted so the caller can fall back to the
    // generic mailto: URL (e.g. on mobile).
    Q_INVOKABLE bool composeEmail(const QString& address,
                                  const QString& subject,
                                  const QString& body);
};
