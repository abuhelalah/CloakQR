#pragma once

#include <QMutex>
#include <QString>

// Thread-safe logger.  All output is prefixed with a timestamp and level tag
// and forwarded to qDebug / qWarning / qCritical so it is captured by Qt's
// message handler (and therefore by the CI log sink).
//
// Usage:
//   Logger::info("QrEncoder", "encoded %1 modules", width*width);
//   Logger::warn("QrEncoder", "empty text supplied");
//   Logger::error("QrEncoder", "libqrencode returned nullptr");
class Logger
{
public:
    enum class Level { Info, Warning, Error };

    static void info(const char* category, const QString& message);
    static void warn(const char* category, const QString& message);
    static void error(const char* category, const QString& message);

private:
    static void log(Level level, const char* category, const QString& message);
    static QMutex s_mutex;
};
