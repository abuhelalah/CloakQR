#include <QtTest>

#include "scanhistorymodel.h"

class TestScanHistory : public QObject
{
    Q_OBJECT

private slots:
    void openInMemory();
    void addEntry_appendsToModel();
    void addEntry_persistsAcrossReload();
    void clear_removesAllEntries();
    void roleNames_containsExpectedKeys();
    void dataOutOfBounds_returnsInvalid();
};

void TestScanHistory::openInMemory()
{
    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));
    QCOMPARE(model.count(), 0);
    QCOMPARE(model.rowCount(), 0);
}

void TestScanHistory::addEntry_appendsToModel()
{
    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));

    model.addEntry(QStringLiteral("https://example.com"), QStringLiteral("url"));
    model.addEntry(QStringLiteral("plain text"), QStringLiteral("text"));

    QCOMPARE(model.count(), 2);
    QCOMPARE(model.rowCount(), 2);

    const QModelIndex first = model.index(0);
    QCOMPARE(model.data(first, ScanHistoryModel::ContentRole).toString(),
             QStringLiteral("https://example.com"));
    QCOMPARE(model.data(first, ScanHistoryModel::TypeRole).toString(),
             QStringLiteral("url"));

    const QModelIndex second = model.index(1);
    QCOMPARE(model.data(second, ScanHistoryModel::TypeRole).toString(),
             QStringLiteral("text"));
}

void TestScanHistory::addEntry_persistsAcrossReload()
{
    QTemporaryDir tmpDir;
    QVERIFY(tmpDir.isValid());
    const QString dbPath = tmpDir.filePath(QStringLiteral("test.db"));

    {
        ScanHistoryModel model;
        QVERIFY(model.open(dbPath));
        model.addEntry(QStringLiteral("persistent"), QStringLiteral("text"));
        QCOMPARE(model.count(), 1);
    }

    // Re-open from the same file.
    ScanHistoryModel model2;
    QVERIFY(model2.open(dbPath));
    QCOMPARE(model2.count(), 1);
    QCOMPARE(model2.data(model2.index(0), ScanHistoryModel::ContentRole).toString(),
             QStringLiteral("persistent"));
}

void TestScanHistory::clear_removesAllEntries()
{
    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));

    model.addEntry(QStringLiteral("a"), QStringLiteral("text"));
    model.addEntry(QStringLiteral("b"), QStringLiteral("text"));
    QCOMPARE(model.count(), 2);

    model.clear();
    QCOMPARE(model.count(), 0);
    QCOMPARE(model.rowCount(), 0);
}

void TestScanHistory::roleNames_containsExpectedKeys()
{
    ScanHistoryModel model;
    const QHash<int, QByteArray> roles = model.roleNames();
    QVERIFY(roles.values().contains("content"));
    QVERIFY(roles.values().contains("timestamp"));
    QVERIFY(roles.values().contains("contentType"));
}

void TestScanHistory::dataOutOfBounds_returnsInvalid()
{
    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));

    QVERIFY(!model.data(model.index(-1), ScanHistoryModel::ContentRole).isValid());
    QVERIFY(!model.data(model.index(0), ScanHistoryModel::ContentRole).isValid());
    QVERIFY(!model.data(QModelIndex(), ScanHistoryModel::ContentRole).isValid());
}

QTEST_MAIN(TestScanHistory)
#include "tst_scanhistory.moc"
