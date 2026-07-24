#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QStandardPaths>

#include "appengine.h"
#include "billingbridge.h"
#include "cryptohelper.h"
#include "fileexporter.h"
#include "qmlbindings.h"
#include "qrgenerator.h"
#include "qrdecoder.h"
#include "scanhistorymodel.h"
#include "qrimageprovider.h"

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("CloakQR"));
    app.setApplicationName(QStringLiteral("CloakQR"));

    QQmlApplicationEngine engine;

    AppEngine appEngine;
    QrDecoder decoder;
    QrGenerator generator;
    FileExporter exporter;
    CryptoHelper crypto;
    BillingBridge billing;
    ScanHistoryModel history;

    const QString dbDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dbDir);
    history.open(dbDir + QStringLiteral("/history.db"));

    engine.addImageProvider(QStringLiteral("qrcode"), new QrImageProvider(&generator));

    QmlBindings::bindObjects(engine, appEngine, decoder, generator, exporter, crypto, billing, history);

    const QUrl url(QStringLiteral("qrc:/qt/qml/CloakQR/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() {
        QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
