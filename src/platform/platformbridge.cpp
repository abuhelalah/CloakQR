#include "platformbridge.h"

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniEnvironment>
#include <QJniObject>
#endif

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
#include <QDesktopServices>
#include <QProcess>
#include <QStandardPaths>
#include <QStringList>
#include <QUrl>
#include <QUrlQuery>
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

bool PlatformBridge::contactInsertSupported() const
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

bool PlatformBridge::addContact(const QString& name,
                                const QString& phone,
                                const QString& email)
{
#ifdef Q_OS_ANDROID
    if (name.isEmpty() && phone.isEmpty() && email.isEmpty())
        return false;

    QJniEnvironment env;

    const QJniObject action = QJniObject::fromString(
        QStringLiteral("android.intent.action.INSERT"));
    QJniObject intent("android/content/Intent",
                      "(Ljava/lang/String;)V",
                      action.object<jstring>());
    if (!intent.isValid())
        return false;

    const QJniObject type = QJniObject::fromString(
        QStringLiteral("vnd.android.cursor.dir/contact"));
    intent.callObjectMethod("setType",
                            "(Ljava/lang/String;)Landroid/content/Intent;",
                            type.object<jstring>());

    const auto putExtra = [&intent](const char* key, const QString& value) {
        if (value.isEmpty())
            return;
        const QJniObject jkey = QJniObject::fromString(QString::fromLatin1(key));
        const QJniObject jval = QJniObject::fromString(value);
        intent.callObjectMethod(
            "putExtra",
            "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;",
            jkey.object<jstring>(), jval.object<jstring>());
    };
    // Keys are the stable ContactsContract.Intents.Insert constants.
    putExtra("name", name);
    putExtra("phone", phone);
    putExtra("email", email);

    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", 0x10000000);

    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid())
        return false;
    context.callMethod<void>("startActivity",
                             "(Landroid/content/Intent;)V",
                             intent.object());

    return !env.checkAndClearExceptions();
#else
    Q_UNUSED(name);
    Q_UNUSED(phone);
    Q_UNUSED(email);
    return false;
#endif
}

bool PlatformBridge::composeEmail(const QString& address,
                                  const QString& subject,
                                  const QString& body)
{
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    QUrl mailto;
    mailto.setScheme(QStringLiteral("mailto"));
    mailto.setPath(address);
    QUrlQuery query;
    if (!subject.isEmpty())
        query.addQueryItem(QStringLiteral("subject"), subject);
    if (!body.isEmpty())
        query.addQueryItem(QStringLiteral("body"), body);
    if (!query.isEmpty())
        mailto.setQuery(query);
    const QString mailtoStr = mailto.toString(QUrl::FullyEncoded);

    // Prefer a real desktop mail client so we never fall through to a browser
    // when one is installed. The mailto: URL is understood by all of these.
    static const QStringList kMailClients = {
        QStringLiteral("thunderbird"), QStringLiteral("evolution"),
        QStringLiteral("geary"),       QStringLiteral("kmail"),
        QStringLiteral("mailspring"),  QStringLiteral("claws-mail"),
        QStringLiteral("sylpheed"),    QStringLiteral("outlook")
    };
    for (const QString& client : kMailClients) {
        const QString path = QStandardPaths::findExecutable(client);
        if (path.isEmpty())
            continue;
        if (QProcess::startDetached(path, QStringList{ mailtoStr }))
            return true;
    }

    // No dedicated client found: let xdg-email pick the configured handler, and
    // fall back to the generic URL opener if xdg-utils is unavailable.
    if (QProcess::startDetached(QStringLiteral("xdg-email"), QStringList{ mailtoStr }))
        return true;
    return QDesktopServices::openUrl(mailto);
#else
    Q_UNUSED(address);
    Q_UNUSED(subject);
    Q_UNUSED(body);
    return false;
#endif
}
