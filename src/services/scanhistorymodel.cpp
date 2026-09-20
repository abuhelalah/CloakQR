#include "scanhistorymodel.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QLocale>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>
#include <QtConcurrent/QtConcurrentRun>

static constexpr auto kTable = "scan_history";

QString ScanHistoryModel::displayTimeFor(const QString& isoTimestamp)
{
    const QDateTime dt = QDateTime::fromString(isoTimestamp, Qt::ISODate);
    return dt.isValid() ? QLocale().toString(dt.time(), QLocale::ShortFormat) : isoTimestamp;
}

QString ScanHistoryModel::dayKeyFor(const QString& isoTimestamp)
{
    const QDate date = QDateTime::fromString(isoTimestamp, Qt::ISODate).date();
    return date.isValid() ? date.toString(QStringLiteral("yyyy-MM-dd")) : QString();
}

ScanHistoryModel::ScanHistoryModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

ScanHistoryModel::~ScanHistoryModel()
{
    if (m_db.isOpen())
        m_db.close();

    if (!m_connectionName.isEmpty()) {
        m_db = QSqlDatabase();
        QSqlDatabase::removeDatabase(m_connectionName);
    }
}

bool ScanHistoryModel::open(const QString& dbPath)
{
    m_dbPath = dbPath;
    if (!ensureDbOpen())
        return false;
    loadFromDb();
    m_loaded = true;
    return true;
}

void ScanHistoryModel::setDbPath(const QString& dbPath)
{
    m_dbPath = dbPath;
}

bool ScanHistoryModel::ensureDbOpen()
{
    if (m_dbOpen)
        return true;
    if (m_dbPath.isEmpty())
        return false;

    if (m_dbPath != QStringLiteral(":memory:")) {
        const QString dir = QFileInfo(m_dbPath).absolutePath();
        if (!dir.isEmpty())
            QDir().mkpath(dir);
    }

    m_connectionName = QStringLiteral("cloakqr_history_") + QUuid::createUuid().toString(QUuid::WithoutBraces);
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
    m_db.setDatabaseName(m_dbPath);

    if (!m_db.open())
        return false;

    QSqlQuery q(m_db);
    const bool ok = q.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS %1 ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  content     TEXT    NOT NULL,"
        "  type        TEXT    NOT NULL DEFAULT 'text',"
        "  scanned_at  TEXT    NOT NULL,"
        "  origin      TEXT    NOT NULL DEFAULT 'scanned'"
        ")").arg(QString::fromLatin1(kTable)));

    if (!ok)
        return false;

    // Databases created by older builds lack the "origin" column; add it in
    // place so existing history keeps working and reads back as "scanned".
    QSqlQuery columns(m_db);
    if (!columns.exec(QStringLiteral("PRAGMA table_info(%1)").arg(QString::fromLatin1(kTable))))
        return false;
    bool hasOrigin = false;
    while (columns.next()) {
        if (columns.value(1).toString() == QStringLiteral("origin")) {
            hasOrigin = true;
            break;
        }
    }
    if (!hasOrigin) {
        QSqlQuery alter(m_db);
        if (!alter.exec(QStringLiteral("ALTER TABLE %1 ADD COLUMN origin TEXT NOT NULL DEFAULT 'scanned'")
                            .arg(QString::fromLatin1(kTable))))
            return false;
    }

    m_dbOpen = true;
    return true;
}

void ScanHistoryModel::ensureLoaded()
{
    if (m_loaded || m_loadInFlight)
        return;
    m_loadInFlight = true;
    if (!ensureDbOpen()) {
        m_loadInFlight = false;
        m_loaded = true;
        return;
    }
    startAsyncLoad();
}

void ScanHistoryModel::startAsyncLoad()
{
    const QString dbPath = m_dbPath;
    auto* watcher = new QFutureWatcher<QVector<Entry>>(this);
    connect(watcher, &QFutureWatcher<QVector<Entry>>::finished, this, [this, watcher]() {
        const QVector<Entry> rows = watcher->result();
        watcher->deleteLater();

        // A write landed while the snapshot was being taken; reload once so it
        // isn't dropped. Rare in practice (writes happen on the Scan tab).
        if (m_dirty) {
            m_dirty = false;
            startAsyncLoad();
            return;
        }

        m_loadInFlight = false;
        m_loaded = true;
        if (!rows.isEmpty()) {
            beginResetModel();
            m_entries = rows;
            endResetModel();
            emit countChanged();
        }
        emit loaded();
    });
    watcher->setFuture(QtConcurrent::run([dbPath]() {
        QVector<Entry> rows;
        const QString conn = QStringLiteral("cloakqr_history_load_")
            + QUuid::createUuid().toString(QUuid::WithoutBraces);
        {
            QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), conn);
            db.setDatabaseName(dbPath);
            if (db.open()) {
                QSqlQuery q(db);
                if (q.exec(QStringLiteral("SELECT id, content, scanned_at, type, origin FROM %1 ORDER BY id DESC")
                               .arg(QString::fromLatin1(kTable)))) {
                    while (q.next()) {
                        const QString ts = q.value(2).toString();
                        rows.append({
                            q.value(0).toInt(),
                            q.value(1).toString(),
                            ts,
                            q.value(3).toString(),
                            q.value(4).toString(),
                            ScanHistoryModel::displayTimeFor(ts),
                            ScanHistoryModel::dayKeyFor(ts)
                        });
                    }
                }
            }
        }
        QSqlDatabase::removeDatabase(conn);
        return rows;
    }));
}

void ScanHistoryModel::addEntry(const QString& content, const QString& type, const QString& origin)
{
    if (!ensureDbOpen())
        return;

    const QString timestamp = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("INSERT INTO %1 (content, type, scanned_at, origin) VALUES (?, ?, ?, ?)").arg(
        QString::fromLatin1(kTable)));
    q.addBindValue(content);
    q.addBindValue(type);
    q.addBindValue(timestamp);
    q.addBindValue(origin);

    if (!q.exec())
        return;

    const int newId = q.lastInsertId().toInt();

    beginInsertRows(QModelIndex(), 0, 0);
    m_entries.prepend({newId, content, timestamp, type, origin,
                       displayTimeFor(timestamp), dayKeyFor(timestamp)});
    endInsertRows();

    emit countChanged();

    // Enforce the cap: silently drop the oldest rows beyond the limit so the
    // on-device database never grows unbounded.
    if (m_entries.size() > kMaxHistoryEntries) {
        QSqlQuery del(m_db);
        if (del.exec(QStringLiteral(
                "DELETE FROM %1 WHERE id NOT IN "
                "(SELECT id FROM %1 ORDER BY id DESC LIMIT %2)")
                         .arg(QString::fromLatin1(kTable))
                         .arg(kMaxHistoryEntries))) {
            const int firstRemoved = kMaxHistoryEntries;
            const int lastRemoved = m_entries.size() - 1;
            beginRemoveRows(QModelIndex(), firstRemoved, lastRemoved);
            m_entries.resize(kMaxHistoryEntries);
            endRemoveRows();
            emit countChanged();
        }
    }

    if (m_loadInFlight)
        m_dirty = true;
}

void ScanHistoryModel::clear()
{
    if (!ensureDbOpen())
        return;

    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral("DELETE FROM %1").arg(QString::fromLatin1(kTable))))
        return;

    if (!m_entries.isEmpty()) {
        beginResetModel();
        m_entries.clear();
        endResetModel();
        emit countChanged();
    }
    if (m_loadInFlight)
        m_dirty = true;
}

void ScanHistoryModel::removeEntry(int row)
{
    if (row < 0 || row >= m_entries.size() || !ensureDbOpen())
        return;

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM %1 WHERE id = ?").arg(
        QString::fromLatin1(kTable)));
    q.addBindValue(m_entries.at(row).id);
    if (!q.exec())
        return;

    beginRemoveRows(QModelIndex(), row, row);
    m_entries.removeAt(row);
    endRemoveRows();
    emit countChanged();
    if (m_loadInFlight)
        m_dirty = true;
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
    case DayKeyRole:    return entry.dayKey;
    case OriginRole:    return entry.origin;
    case DisplayTimeRole: return entry.displayTime;
    default:            return QVariant();
    }
}

QHash<int, QByteArray> ScanHistoryModel::roleNames() const
{
    return {
        {ContentRole,   "content"},
        {TimestampRole, "timestamp"},
        {TypeRole,      "contentType"},
        {DayKeyRole,    "dayKey"},
        {OriginRole,    "origin"},
        {DisplayTimeRole, "displayTime"}
    };
}

void ScanHistoryModel::loadFromDb()
{
    if (!m_db.isOpen())
        return;

    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral("SELECT id, content, scanned_at, type, origin FROM %1 ORDER BY id DESC").arg(
            QString::fromLatin1(kTable))))
        return;

    QVector<Entry> loaded;
    while (q.next()) {
        const QString ts = q.value(2).toString();
        loaded.append({
            q.value(0).toInt(),
            q.value(1).toString(),
            ts,
            q.value(3).toString(),
            q.value(4).toString(),
            displayTimeFor(ts),
            dayKeyFor(ts)
        });
    }

    if (!loaded.isEmpty()) {
        beginResetModel();
        m_entries = loaded;
        endResetModel();
        emit countChanged();
    }
}
