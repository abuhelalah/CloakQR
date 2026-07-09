#include "fileexporter.h"

#include <QFile>
#include <QTextStream>

FileExporter::FileExporter(QObject* parent)
    : QObject(parent)
{
}

bool FileExporter::exportBatchToCSV(const QStringList& rows, const QUrl& outputUrl) const
{
    QFile file(outputUrl.toString());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    QTextStream out(&file);
    out << "value\n";
    for (const QString& row : rows)
        out << '"' << row << "\"\n";

    file.close();
    return true;
}
