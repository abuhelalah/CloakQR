#pragma once

class QQmlApplicationEngine;
class AppEngine;
class QrDecoder;
class QrGenerator;
class FileExporter;
class CryptoHelper;
class BillingBridge;
class ScanHistoryModel;

namespace QmlBindings {
void bindObjects(
    QQmlApplicationEngine& engine,
    AppEngine& appEngine,
    QrDecoder& decoder,
    QrGenerator& generator,
    FileExporter& exporter,
    CryptoHelper& crypto,
    BillingBridge& billing,
    ScanHistoryModel& history);
}
