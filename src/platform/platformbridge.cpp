#include "platformbridge.h"

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniEnvironment>
#include <QJniObject>
#endif

PlatformBridge::PlatformBridge(QObject* parent)
    : QObject(parent)
{
}

bool PlatformBridge::wifiConnectSupported() const
{
#ifdef Q_OS_ANDROID
    return true;
#else
    return false;
#endif
}

bool PlatformBridge::connectToWifi(const QString& ssid,
                                   const QString& password,
                                   const QString& security,
                                   bool hidden)
{
#ifdef Q_OS_ANDROID
    if (ssid.isEmpty())
        return false;

    QJniEnvironment env;

    QJniObject builder("android/net/wifi/WifiNetworkSuggestion$Builder");
    if (!builder.isValid())
        return false;

    const QJniObject jssid = QJniObject::fromString(ssid);
    builder = builder.callObjectMethod(
        "setSsid",
        "(Ljava/lang/String;)Landroid/net/wifi/WifiNetworkSuggestion$Builder;",
        jssid.object<jstring>());

    const QString sec = security.toUpper();
    const bool hasPassword = !password.isEmpty()
        && sec != QLatin1String("NOPASS") && sec != QLatin1String("NONE");
    if (hasPassword) {
        const QJniObject jpass = QJniObject::fromString(password);
        if (sec.contains(QLatin1String("SAE")) || sec.contains(QLatin1String("WPA3"))) {
            builder = builder.callObjectMethod(
                "setWpa3Passphrase",
                "(Ljava/lang/String;)Landroid/net/wifi/WifiNetworkSuggestion$Builder;",
                jpass.object<jstring>());
        } else {
            builder = builder.callObjectMethod(
                "setWpa2Passphrase",
                "(Ljava/lang/String;)Landroid/net/wifi/WifiNetworkSuggestion$Builder;",
                jpass.object<jstring>());
        }
    }
    if (hidden) {
        builder = builder.callObjectMethod(
            "setIsHiddenSsid",
            "(Z)Landroid/net/wifi/WifiNetworkSuggestion$Builder;",
            true);
    }
    if (!builder.isValid())
        return false;

    const QJniObject suggestion = builder.callObjectMethod(
        "build", "()Landroid/net/wifi/WifiNetworkSuggestion;");
    if (!suggestion.isValid())
        return false;

    QJniObject list("java/util/ArrayList");
    if (!list.isValid())
        return false;
    list.callMethod<jboolean>("add", "(Ljava/lang/Object;)Z", suggestion.object());

    const QJniObject action = QJniObject::fromString(
        QStringLiteral("android.settings.WIFI_ADD_NETWORKS"));
    QJniObject intent("android/content/Intent",
                      "(Ljava/lang/String;)V",
                      action.object<jstring>());
    if (!intent.isValid())
        return false;

    const QJniObject extraKey = QJniObject::fromString(
        QStringLiteral("android.provider.extra.WIFI_NETWORK_LIST"));
    intent.callObjectMethod(
        "putParcelableArrayListExtra",
        "(Ljava/lang/String;Ljava/util/ArrayList;)Landroid/content/Intent;",
        extraKey.object<jstring>(), list.object());
    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", 0x10000000);

    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid())
        return false;
    context.callMethod<void>("startActivity",
                             "(Landroid/content/Intent;)V",
                             intent.object());

    return !env.checkAndClearExceptions();
#else
    Q_UNUSED(ssid);
    Q_UNUSED(password);
    Q_UNUSED(security);
    Q_UNUSED(hidden);
    return false;
#endif
}
