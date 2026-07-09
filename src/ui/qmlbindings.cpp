#include "qmlbindings.h"

#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "appengine.h"
#include "billingbridge.h"
#include "cryptohelper.h"
#include "fileexporter.h"
#include "qrgenerator.h"
#include "qrdecoder.h"

namespace QmlBindings {

void bindObjects(
    QQmlApplicationEngine& engine,
    AppEngine& appEngine,
    QrDecoder& decoder,
    QrGenerator& generator,
    FileExporter& exporter,
    CryptoHelper& crypto,
    BillingBridge& billing)
{
    QQmlContext* ctx = engine.rootContext();
    ctx->setContextProperty("appEngine", &appEngine);
    ctx->setContextProperty("qrDecoder", &decoder);
    ctx->setContextProperty("qrGenerator", &generator);
    ctx->setContextProperty("fileExporter", &exporter);
    ctx->setContextProperty("cryptoHelper", &crypto);
    ctx->setContextProperty("billingBridge", &billing);
}

}
