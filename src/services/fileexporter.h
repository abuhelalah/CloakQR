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

    // Writes UTF-8 text (e.g. a vCard) to the given file, used by the scan
    // preview to save a contact on desktop platforms. Returns true on success.
    Q_INVOKABLE bool saveTextFile(const QUrl& outputUrl, const QString& text) const;
};
