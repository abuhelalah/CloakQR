#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QLibraryInfo>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QStyleHints>
#include <QTranslator>

#include "appengine.h"
#include "cloakqr_version.h"
#include "cryptohelper.h"
#include "fileexporter.h"
#include "platformbridge.h"
#include "qmlbindings.h"
#include "qrgenerator.h"
#include "qrdecoder.h"
#include "scanhistorymodel.h"
#include "settings.h"
#include "qrimageprovider.h"

#if CLOAKQR_PAID_EDITION
#include "batchgenerator.h"
#include "logooverlaygenerator.h"
#endif

namespace {

// Resolves the effective locale for the requested language code, mapping the
// "system" sentinel to the platform locale.
QString resolveLanguage(const QString& code)
{
    if (code.isEmpty() || code == QLatin1String("system"))
        return QLocale::system().name().section(QLatin1Char('_'), 0, 0);
    return code;
}

// Loads (or reloads) the application translation for the given language into
// the supplied translator and applies the matching layout direction.
void applyLanguage(QGuiApplication& app, QTranslator& translator, const QString& code)
{
    app.removeTranslator(&translator);
    const QString lang = resolveLanguage(code);
    if (translator.load(QStringLiteral(":/i18n/%1").arg(lang)))
        app.installTranslator(&translator);

    const bool rtl = QLocale(lang).textDirection() == Qt::RightToLeft;
    app.setLayoutDirection(rtl ? Qt::RightToLeft : Qt::LeftToRight);
}

// Resolves the Qt color scheme that matches the in-app theme setting. The
// non-native Qt Quick file dialog opens as a separate top-level window whose
// default palette Qt derives from the reported color scheme, so forcing the
// scheme keeps that dialog (and its Basic-styled shortcut sidebar) readable
// in dark mode instead of drawing dark text on the dark dialog.
Qt::ColorScheme schemeForTheme(const QString& theme)
{
    if (theme == QLatin1String("dark"))
        return Qt::ColorScheme::Dark;
    if (theme == QLatin1String("light"))
        return Qt::ColorScheme::Light;
    return Qt::ColorScheme::Unknown; // follow the platform color scheme
}

} // namespace

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("CloakQR"));
    app.setApplicationName(CLOAKQR_PAID_EDITION
                               ? QStringLiteral("CloakQR Pro")
                               : QStringLiteral("CloakQR"));
    app.setApplicationDisplayName(app.applicationName());
    app.setApplicationVersion(QStringLiteral(CLOAKQR_VERSION));
    app.setWindowIcon(QIcon(QStringLiteral(":/images/Logo_QR_icon.png")));

    QQuickStyle::setStyle(QStringLiteral("Material"));

    Settings settings;

    // Keep Qt's reported color scheme in step with the in-app theme so the
    // non-native file dialog (a separate top-level window) stays readable in
    // dark mode.
    const auto applyColorScheme = [&settings]() {
        if (auto* hints = QGuiApplication::styleHints())
            hints->setColorScheme(schemeForTheme(settings.theme()));
    };
    applyColorScheme();
    QObject::connect(&settings, &Settings::themeChanged, &app, applyColorScheme);

    QTranslator translator;
    applyLanguage(app, translator, settings.language());

    AppEngine appEngine;
    QrDecoder decoder;
    QrGenerator generator;
    FileExporter exporter;
    CryptoHelper crypto;
    ScanHistoryModel history;
    QQmlApplicationEngine engine;

    QObject::connect(&settings, &Settings::languageChanged, &app,
                     [&app, &translator, &settings, &engine]() {
                         applyLanguage(app, translator, settings.language());
                         engine.retranslate();
                     });

    const QString dbDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dbDir);
    history.open(dbDir + QStringLiteral("/history.db"));

    engine.addImageProvider(QStringLiteral("qrcode"), new QrImageProvider(&generator));

    QmlBindings::bindObjects(engine, appEngine, decoder, generator, exporter, crypto,
                             history, settings);

    PlatformBridge platformBridge;
    engine.rootContext()->setContextProperty("platformBridge", &platformBridge);

#if CLOAKQR_PAID_EDITION
    BatchGenerator batchGenerator;
    LogoOverlayGenerator logoOverlayGenerator;
    engine.rootContext()->setContextProperty("batchGenerator", &batchGenerator);
    engine.rootContext()->setContextProperty("logoOverlayGenerator", &logoOverlayGenerator);
#endif

    const QUrl url(QStringLiteral("qrc:/qt/qml/CloakQR/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() {
        QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
