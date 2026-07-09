#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "appengine.h"
#include "billingbridge.h"
#include "cryptohelper.h"
#include "fileexporter.h"
#include "qmlbindings.h"
#include "qrgenerator.h"
#include "qrdecoder.h"

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    AppEngine appEngine;
    QrDecoder decoder;
    QrGenerator generator;
    FileExporter exporter;
    CryptoHelper crypto;
    BillingBridge billing;

    QmlBindings::bindObjects(engine, appEngine, decoder, generator, exporter, crypto, billing);

    const QUrl url(QStringLiteral("qrc:/qt/qml/CloakQR/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() {
        QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
