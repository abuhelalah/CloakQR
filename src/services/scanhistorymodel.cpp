#include "scanhistorymodel.h"

#include <QDateTime>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>

static constexpr auto kTable = "scan_history";

ScanHistoryModel::ScanHistoryModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

ScanHistoryModel::~ScanHistoryModel()
{
    if (m_db.isOpen())
        m_db.close();

    if (!m_connectionName.isEmpty())
        QSqlDatabase::removeDatabase(m_connectionName);
}

bool ScanHistoryModel::open(const QString& dbPath)
{
    m_connectionName = QStringLiteral("cloakqr_history_") + QUuid::createUuid().toString(QUuid::WithoutBraces);
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
    m_db.setDatabaseName(dbPath);

    if (!m_db.open())
        return false;

    QSqlQuery q(m_db);
    const bool ok = q.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS %1 ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  content     TEXT    NOT NULL,"
        "  type        TEXT    NOT NULL DEFAULT 'text',"
        "  scanned_at  TEXT    NOT NULL"
        ")").arg(QString::fromLatin1(kTable)));

    if (!ok)
        return false;

    loadFromDb();
    return true;
}

void ScanHistoryModel::addEntry(const QString& content, const QString& type)
{
    if (!m_db.isOpen())
        return;

    const QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("INSERT INTO %1 (content, type, scanned_at) VALUES (?, ?, ?)").arg(
        QString::fromLatin1(kTable)));
    q.addBindValue(content);
    q.addBindValue(type);
    q.addBindValue(timestamp);

    if (!q.exec())
        return;

    const int newId = q.lastInsertId().toInt();
    const int pos = m_entries.size();

    beginInsertRows(QModelIndex(), pos, pos);
    m_entries.append({newId, content, timestamp, type});
    endInsertRows();

    emit countChanged();
}

void ScanHistoryModel::clear()
{
    if (!m_db.isOpen())
        return;

    QSqlQuery q(m_db);
    q.exec(QStringLiteral("DELETE FROM %1").arg(QString::fromLatin1(kTable)));

    if (!m_entries.isEmpty()) {
        beginResetModel();
        m_entries.clear();
        endResetModel();
        emit countChanged();
    }
}

int ScanHistoryModel::count() const
{
    return m_entries.size();
}

int ScanHistoryModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid())
        return 0;
    return m_entries.size();
}

QVariant ScanHistoryModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return QVariant();

    const Entry& entry = m_entries.at(index.row());

    switch (role) {
    case ContentRole:   return entry.content;
    case TimestampRole: return entry.timestamp;
    case TypeRole:      return entry.type;
    default:            return QVariant();
    }
}

QHash<int, QByteArray> ScanHistoryModel::roleNames() const
{
    return {
        {ContentRole,   "content"},
        {TimestampRole, "timestamp"},
        {TypeRole,      "contentType"}
    };
}

void ScanHistoryModel::loadFromDb()
{
    if (!m_db.isOpen())
        return;

    QSqlQuery q(m_db);
    q.exec(QStringLiteral("SELECT id, content, scanned_at, type FROM %1 ORDER BY id ASC").arg(
        QString::fromLatin1(kTable)));

    QVector<Entry> loaded;
    while (q.next()) {
        loaded.append({
            q.value(0).toInt(),
            q.value(1).toString(),
            q.value(2).toString(),
            q.value(3).toString()
        });
    }

    if (!loaded.isEmpty()) {
        beginResetModel();
        m_entries = loaded;
        endResetModel();
        emit countChanged();
    }
}
