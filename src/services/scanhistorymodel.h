#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QSqlDatabase>
#include <QString>
#include <QVector>

class ScanHistoryModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        ContentRole   = Qt::UserRole + 1,
        TimestampRole,
        TypeRole,
        DayKeyRole,
        OriginRole,
        DisplayTimeRole
    };
    Q_ENUM(Roles)

    explicit ScanHistoryModel(QObject* parent = nullptr);
    ~ScanHistoryModel() override;

    // History is capped so the on-device database stays bounded: the oldest
    // entries are silently evicted once this limit is exceeded.
    static constexpr int kMaxHistoryEntries = 1000;

    // Precomputed display strings for a stored ISO timestamp. displayTime uses
    // the short locale time format (identical to Date.toLocaleTimeString in
    // QML); dayKey is the "yyyy-MM-dd" key used for History section headers.
    static QString displayTimeFor(const QString& isoTimestamp);
    static QString dayKeyFor(const QString& isoTimestamp);

    // Opens the database and loads it synchronously (tests / CLI).
    bool open(const QString& dbPath);

    // Records the database path without opening it. The app calls this at
    // startup and defers the actual open/load until ensureLoaded().
    void setDbPath(const QString& dbPath);

    // Opens the database (lazily) and loads rows on a worker thread, then
    // notifies the view. Idempotent; safe on every History/Settings visit.
    Q_INVOKABLE void ensureLoaded();

    Q_INVOKABLE void addEntry(const QString& content, const QString& type = QStringLiteral("text"),
                              const QString& origin = QStringLiteral("scanned"));
    Q_INVOKABLE void removeEntry(int row);
    Q_INVOKABLE void clear();
    Q_INVOKABLE int  count() const;

    // QAbstractListModel interface
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void countChanged();
    void loaded();

private:
    struct Entry {
        int     id;
        QString content;
        QString timestamp;
        QString type;
        QString origin;
        QString displayTime; // precomputed short locale time (e.g. "4:10 PM")
        QString dayKey;      // precomputed "yyyy-MM-dd" grouping key
    };

    bool ensureDbOpen();
    void loadFromDb();
    void startAsyncLoad();

    QVector<Entry> m_entries;
    QSqlDatabase   m_db;
    QString        m_connectionName;
    QString        m_dbPath;
    bool           m_dbOpen = false;
    bool           m_loaded = false;
    bool           m_loadInFlight = false;
    bool           m_dirty = false;
};
