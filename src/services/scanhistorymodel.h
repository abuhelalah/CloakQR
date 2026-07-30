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
        TypeRole
    };
    Q_ENUM(Roles)

    explicit ScanHistoryModel(QObject* parent = nullptr);
    ~ScanHistoryModel() override;

    bool open(const QString& dbPath);

    Q_INVOKABLE void addEntry(const QString& content, const QString& type = QStringLiteral("text"));
    Q_INVOKABLE void clear();
    Q_INVOKABLE int  count() const;

    // QAbstractListModel interface
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void countChanged();

private:
    struct Entry {
        int     id;
        QString content;
        QString timestamp;
        QString type;
    };

    void loadFromDb();

    QVector<Entry> m_entries;
    QSqlDatabase   m_db;
    QString        m_connectionName;
};
