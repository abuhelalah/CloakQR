#include "platformbridge.h"

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniEnvironment>
#include <QJniObject>
#include <QMetaObject>
#include <QUrl>
#include <jni.h>
#endif

#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
#include <QDesktopServices>
#include <QProcess>
#include <QStandardPaths>
#include <QStringList>
#include <QUrl>
#include <QUrlQuery>
#endif

#ifdef Q_OS_ANDROID
namespace {

// The bridge lives for the whole application lifetime, so a plain pointer is
// enough to route the JNI callback back to the (single) instance.
PlatformBridge* s_instance = nullptr;

// Called by BiometricAuthHelper.onResult on its executor thread.
void onBiometricResultNative(JNIEnv* /*env*/, jobject /*thiz*/, jint code)
{
    PlatformBridge* bridge = s_instance;
    if (!bridge)
        return;
    const bool success = (code == 0);
    QMetaObject::invokeMethod(bridge, [bridge, success]() {
        emit bridge->biometricAuthenticated(success);
    }, Qt::QueuedConnection);
}

} // namespace
#endif

PlatformBridge::PlatformBridge(QObject* parent)
    : QObject(parent)
{
#ifdef Q_OS_ANDROID
    s_instance = this;
    registerNativeMethods();
#endif
}

PlatformBridge::~PlatformBridge()
{
#ifdef Q_OS_ANDROID
    if (s_instance == this)
        s_instance = nullptr;
#endif
}

#ifdef Q_OS_ANDROID
void PlatformBridge::registerNativeMethods()
{
    QJniEnvironment env;
    JNINativeMethod methods[] = {
        { const_cast<char*>("onResult"), const_cast<char*>("(I)V"),
          reinterpret_cast<void*>(&onBiometricResultNative) }
    };
    env.registerNativeMethods(
        "com/abuhelalah/cloakqr/BiometricAuthHelper", methods, 1);
}
#endif

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

bool PlatformBridge::calendarInsertSupported() const
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

bool PlatformBridge::addCalendarEvent(const QString& title,
                                      const QString& description,
                                      const QString& location,
                                      qint64 startMillis,
                                      qint64 endMillis)
{
#ifdef Q_OS_ANDROID
    QJniEnvironment env;

    const QJniObject action = QJniObject::fromString(
        QStringLiteral("android.intent.action.INSERT"));
    QJniObject intent("android/content/Intent",
                      "(Ljava/lang/String;)V",
                      action.object<jstring>());
    if (!intent.isValid())
        return false;

    // CalendarContract.Events.CONTENT_URI — "content://com.android.calendar/events".
    const QJniObject uriString = QJniObject::fromString(
        QStringLiteral("content://com.android.calendar/events"));
    const QJniObject uri = QJniObject::callStaticObjectMethod(
        "android/net/Uri",
        "parse",
        "(Ljava/lang/String;)Landroid/net/Uri;",
        uriString.object<jstring>());
    if (uri.isValid())
        intent.callObjectMethod("setData",
                                "(Landroid/net/Uri;)Landroid/content/Intent;",
                                uri.object());

    const auto putString = [&intent](const char* key, const QString& value) {
        if (value.isEmpty())
            return;
        const QJniObject jkey = QJniObject::fromString(QString::fromLatin1(key));
        const QJniObject jval = QJniObject::fromString(value);
        intent.callObjectMethod(
            "putExtra",
            "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;",
            jkey.object<jstring>(), jval.object<jstring>());
    };
    // Keys are the stable CalendarContract.Events / EXTRA_EVENT constants.
    putString("title", title);
    putString("description", description);
    putString("eventLocation", location);

    if (startMillis > 0) {
        const QJniObject jkey = QJniObject::fromString(
            QStringLiteral("beginTime"));
        intent.callObjectMethod(
            "putExtra",
            "(Ljava/lang/String;J)Landroid/content/Intent;",
            jkey.object<jstring>(), jlong(startMillis));
    }
    if (endMillis > 0) {
        const QJniObject jkey = QJniObject::fromString(
            QStringLiteral("endTime"));
        intent.callObjectMethod(
            "putExtra",
            "(Ljava/lang/String;J)Landroid/content/Intent;",
            jkey.object<jstring>(), jlong(endMillis));
    }

    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", 0x10000000);

    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid())
        return false;
    context.callMethod<void>("startActivity",
                             "(Landroid/content/Intent;)V",
                             intent.object());

    return !env.checkAndClearExceptions();
#else
    Q_UNUSED(title);
    Q_UNUSED(description);
    Q_UNUSED(location);
    Q_UNUSED(startMillis);
    Q_UNUSED(endMillis);
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

bool PlatformBridge::shareFile(const QString& path)
{
#ifdef Q_OS_ANDROID
    // Accept both plain filesystem paths and file:// URLs.
    const QString localPath = path.startsWith(QLatin1String("file:"))
        ? QUrl(path).toLocalFile() : path;
    if (localPath.isEmpty())
        return false;

    QJniEnvironment env;
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid())
        return false;

    // The manifest registers a FileProvider under "<applicationId>.qtprovider".
    const QJniObject packageName = context.callObjectMethod(
        "getPackageName", "()Ljava/lang/String;");
    const QString authority = packageName.toString() + QStringLiteral(".qtprovider");

    const QJniObject jpath = QJniObject::fromString(localPath);
    const QJniObject file("java/io/File", "(Ljava/lang/String;)V",
                          jpath.object<jstring>());
    if (!file.isValid())
        return false;

    const QJniObject jauth = QJniObject::fromString(authority);
    const QJniObject uri = QJniObject::callStaticObjectMethod(
        "androidx/core/content/FileProvider",
        "getUriForFile",
        "(Landroid/content/Context;Ljava/lang/String;Ljava/io/File;)Landroid/net/Uri;",
        context.object(), jauth.object<jstring>(), file.object());
    if (!uri.isValid()) {
        env.checkAndClearExceptions();
        return false;
    }

    const QJniObject action = QJniObject::fromString(
        QStringLiteral("android.intent.action.SEND"));
    QJniObject intent("android/content/Intent", "(Ljava/lang/String;)V",
                      action.object<jstring>());
    if (!intent.isValid())
        return false;

    const QJniObject mime = QJniObject::fromString(QStringLiteral("image/png"));
    intent.callObjectMethod("setType", "(Ljava/lang/String;)Landroid/content/Intent;",
                            mime.object<jstring>());

    const QJniObject streamKey = QJniObject::fromString(
        QStringLiteral("android.intent.extra.STREAM"));
    intent.callObjectMethod(
        "putExtra",
        "(Ljava/lang/String;Landroid/os/Parcelable;)Landroid/content/Intent;",
        streamKey.object<jstring>(), uri.object());

    // FLAG_GRANT_READ_URI_PERMISSION so the receiving app can read the URI.
    intent.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", 0x1);

    const QJniObject title = QJniObject::fromString(QStringLiteral("Share QR code"));
    const QJniObject chooser = QJniObject::callStaticObjectMethod(
        "android/content/Intent",
        "createChooser",
        "(Landroid/content/Intent;Ljava/lang/CharSequence;)Landroid/content/Intent;",
        intent.object(), title.object<jstring>());
    if (!chooser.isValid())
        return false;
    // FLAG_ACTIVITY_NEW_TASK for starting an activity from a non-activity context.
    chooser.callObjectMethod("addFlags", "(I)Landroid/content/Intent;", 0x10000000);

    context.callMethod<void>("startActivity", "(Landroid/content/Intent;)V",
                             chooser.object());
    return !env.checkAndClearExceptions();
#else
    Q_UNUSED(path);
    return false;
#endif
}

bool PlatformBridge::isBiometricAvailable()
{
#ifdef Q_OS_ANDROID
    QJniEnvironment env;
    const QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid())
        return false;

    const bool available = QJniObject::callStaticMethod<jboolean>(
        "com/abuhelalah/cloakqr/BiometricAuthHelper",
        "isAvailable",
        "(Landroid/content/Context;)Z",
        context.object());
    env.checkAndClearExceptions();
    return available;
#else
    return false;
#endif
}

void PlatformBridge::authenticate()
{
#ifdef Q_OS_ANDROID
    QJniEnvironment env;
    const QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid())
        return;

    const QJniObject title = QJniObject::fromString(QStringLiteral("Unlock CloakQR"));
    const QJniObject subtitle = QJniObject::fromString(QStringLiteral("Confirm it's you"));
    const QJniObject description = QJniObject::fromString(
        QStringLiteral("Use your fingerprint, face or device PIN"));
    const QJniObject cancel = QJniObject::fromString(QStringLiteral("Cancel"));

    QJniObject::callStaticMethod<void>(
        "com/abuhelalah/cloakqr/BiometricAuthHelper",
        "authenticate",
        "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
        context.object(),
        title.object<jstring>(), subtitle.object<jstring>(),
        description.object<jstring>(), cancel.object<jstring>());
    env.checkAndClearExceptions();
#else
    // No-op off Android; the QML caller never invokes it there.
#endif
}
