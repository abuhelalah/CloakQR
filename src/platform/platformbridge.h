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

public:
    explicit PlatformBridge(QObject* parent = nullptr);

    bool wifiConnectSupported() const;

    // Asks the operating system to add/connect to the given Wi-Fi network,
    // showing a native confirmation prompt. Returns true when the request was
    // handed off to the OS.
    Q_INVOKABLE bool connectToWifi(const QString& ssid,
                                   const QString& password,
                                   const QString& security,
                                   bool hidden);
};
