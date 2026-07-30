#pragma once

#include <QObject>
#include <QUrl>
#include <QStringList>

class FileExporter : public QObject
{
    Q_OBJECT

public:
    explicit FileExporter(QObject* parent = nullptr);

    Q_INVOKABLE bool exportBatchToCSV(const QStringList& rows, const QUrl& outputUrl) const;
};
