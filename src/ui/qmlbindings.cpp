#include "qmlbindings.h"

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSortFilterProxyModel>

#include "appengine.h"
#include "cryptohelper.h"
#include "fileexporter.h"
#include "qrgenerator.h"
#include "qrdecoder.h"
#include "scanhistorymodel.h"
#include "settings.h"

namespace QmlBindings {

void bindObjects(
    QQmlApplicationEngine& engine,
    AppEngine& appEngine,
    QrDecoder& decoder,
    QrGenerator& generator,
    FileExporter& exporter,
    CryptoHelper& crypto,
    ScanHistoryModel& history,
    Settings& settings)
{
    QQmlContext* ctx = engine.rootContext();
    ctx->setContextProperty("appEngine", &appEngine);
    ctx->setContextProperty("qrDecoder", &decoder);
    ctx->setContextProperty("qrGenerator", &generator);
    ctx->setContextProperty("fileExporter", &exporter);
    ctx->setContextProperty("cryptoHelper", &crypto);
    ctx->setContextProperty("scanHistory", &history);
    // History page view of the same rows, filterable by origin
    // ("scanned" / "generated") via setFilterFixedString().
    auto* historyFilter = new QSortFilterProxyModel(&history);
    historyFilter->setSourceModel(&history);
    historyFilter->setFilterRole(ScanHistoryModel::OriginRole);
    ctx->setContextProperty("scanHistoryFilter", historyFilter);
    ctx->setContextProperty("appSettings", &settings);
}

}
