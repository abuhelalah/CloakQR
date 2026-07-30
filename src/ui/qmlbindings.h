#pragma once

class QQmlApplicationEngine;
class AppEngine;
class QrDecoder;
class QrGenerator;
class FileExporter;
class CryptoHelper;
class ScanHistoryModel;
class Settings;

namespace QmlBindings {
void bindObjects(
    QQmlApplicationEngine& engine,
    AppEngine& appEngine,
    QrDecoder& decoder,
    QrGenerator& generator,
    FileExporter& exporter,
    CryptoHelper& crypto,
    ScanHistoryModel& history,
    Settings& settings);
}
