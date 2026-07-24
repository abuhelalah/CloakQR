#include "logger.h"

#include <QDateTime>
#include <QDebug>
#include <QMutexLocker>

QMutex Logger::s_mutex;

void Logger::info(const char* category, const QString& message)
{
    log(Level::Info, category, message);
}

void Logger::warn(const char* category, const QString& message)
{
    log(Level::Warning, category, message);
}

void Logger::error(const char* category, const QString& message)
{
    log(Level::Error, category, message);
}

void Logger::log(Level level, const char* category, const QString& message)
{
    QMutexLocker locker(&s_mutex);

    const QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);
    const QString line = QStringLiteral("[%1][%2] %3")
                             .arg(timestamp)
                             .arg(QString::fromLatin1(category))
                             .arg(message);

    switch (level) {
    case Level::Info:
        qDebug().noquote() << line;
        break;
    case Level::Warning:
        qWarning().noquote() << line;
        break;
    case Level::Error:
        qCritical().noquote() << line;
        break;
    }
}
