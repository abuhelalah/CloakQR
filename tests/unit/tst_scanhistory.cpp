#include <QtTest>

#include <QLocale>

#include "scanhistorymodel.h"

class TestScanHistory : public QObject
{
    Q_OBJECT

private slots:
    void openInMemory();
    void addEntry_insertsNewestFirst();
    void addEntry_persistsAcrossReload();
    void clear_removesAllEntries();
    void roleNames_containsExpectedKeys();
    void addEntry_recordsOrigin();
    void dataOutOfBounds_returnsInvalid();
    void displayStrings_matchExpectedFormat();
    void cap_evictsOldestEntries();
    void cap_persistsAcrossReload();
};

void TestScanHistory::openInMemory()
{
    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));
    QCOMPARE(model.count(), 0);
    QCOMPARE(model.rowCount(), 0);
}

void TestScanHistory::addEntry_insertsNewestFirst()
{
    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));

    model.addEntry(QStringLiteral("https://example.com"), QStringLiteral("url"));
    model.addEntry(QStringLiteral("plain text"), QStringLiteral("text"));

    QCOMPARE(model.count(), 2);
    QCOMPARE(model.rowCount(), 2);

    // Newest entries are inserted at the top.
    const QModelIndex first = model.index(0);
    QCOMPARE(model.data(first, ScanHistoryModel::ContentRole).toString(),
             QStringLiteral("plain text"));
    QCOMPARE(model.data(first, ScanHistoryModel::TypeRole).toString(),
             QStringLiteral("text"));

    const QModelIndex second = model.index(1);
    QCOMPARE(model.data(second, ScanHistoryModel::ContentRole).toString(),
             QStringLiteral("https://example.com"));
    QCOMPARE(model.data(second, ScanHistoryModel::TypeRole).toString(),
             QStringLiteral("url"));
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
    QVERIFY(roles.values().contains("dayKey"));
    QVERIFY(roles.values().contains("origin"));
    QVERIFY(roles.values().contains("displayTime"));
}

void TestScanHistory::addEntry_recordsOrigin()
{
    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));

    model.addEntry(QStringLiteral("scanned code"), QStringLiteral("url"));
    model.addEntry(QStringLiteral("made code"), QStringLiteral("text"), QStringLiteral("generated"));

    QCOMPARE(model.data(model.index(0), ScanHistoryModel::OriginRole).toString(),
             QStringLiteral("generated"));
    QCOMPARE(model.data(model.index(1), ScanHistoryModel::OriginRole).toString(),
             QStringLiteral("scanned"));
}

void TestScanHistory::dataOutOfBounds_returnsInvalid()
{
    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));

    QVERIFY(!model.data(model.index(-1), ScanHistoryModel::ContentRole).isValid());
    QVERIFY(!model.data(model.index(0), ScanHistoryModel::ContentRole).isValid());
    QVERIFY(!model.data(QModelIndex(), ScanHistoryModel::ContentRole).isValid());
}

void TestScanHistory::displayStrings_matchExpectedFormat()
{
    const QLocale original = QLocale();

    const QString ts = QStringLiteral("2026-09-19T21:37:00");

    // English (US): "9:37 PM" with a narrow no-break space before "PM".
    QLocale::setDefault(QLocale(QLocale::English, QLocale::UnitedStates));
    QCOMPARE(ScanHistoryModel::displayTimeFor(ts), QStringLiteral("9:37\u202fPM"));
    QCOMPARE(ScanHistoryModel::dayKeyFor(ts), QStringLiteral("2026-09-19"));

    // Arabic (Saudi Arabia): Arabic-Indic digits and the "م" suffix.
    QLocale::setDefault(QLocale(QLocale::Arabic, QLocale::SaudiArabia));
    QCOMPARE(ScanHistoryModel::displayTimeFor(ts), QStringLiteral("\u0669:\u0663\u0667 \u0645"));
    QCOMPARE(ScanHistoryModel::dayKeyFor(ts), QStringLiteral("2026-09-19"));

    // Unparseable timestamps fall back to the raw string and an empty day key.
    QCOMPARE(ScanHistoryModel::displayTimeFor(QStringLiteral("not-a-date")),
             QStringLiteral("not-a-date"));
    QVERIFY(ScanHistoryModel::dayKeyFor(QStringLiteral("not-a-date")).isEmpty());

    QLocale::setDefault(original);
}

void TestScanHistory::cap_evictsOldestEntries()
{
    const int cap = ScanHistoryModel::kMaxHistoryEntries;
    QVERIFY(cap > 0);

    ScanHistoryModel model;
    QVERIFY(model.open(QStringLiteral(":memory:")));

    for (int i = 0; i < cap + 2; ++i)
        model.addEntry(QStringLiteral("entry-") + QString::number(i), QStringLiteral("text"));

    QCOMPARE(model.count(), cap);

    // Newest first: the last inserted entry sits at row 0.
    QCOMPARE(model.data(model.index(0), ScanHistoryModel::ContentRole).toString(),
             QStringLiteral("entry-") + QString::number(cap + 1));

    // The two oldest entries (0 and 1) were evicted; the oldest survivor is the last row.
    QCOMPARE(model.data(model.index(cap - 1), ScanHistoryModel::ContentRole).toString(),
             QStringLiteral("entry-2"));
}

void TestScanHistory::cap_persistsAcrossReload()
{
    const int cap = ScanHistoryModel::kMaxHistoryEntries;
    QTemporaryDir tmpDir;
    QVERIFY(tmpDir.isValid());
    const QString dbPath = tmpDir.filePath(QStringLiteral("cap.db"));

    {
        ScanHistoryModel model;
        QVERIFY(model.open(dbPath));
        for (int i = 0; i < cap + 2; ++i)
            model.addEntry(QStringLiteral("entry-") + QString::number(i), QStringLiteral("text"));
        QCOMPARE(model.count(), cap);
    }

    // The cap must be enforced in the database, not just in the in-memory list.
    ScanHistoryModel reopened;
    QVERIFY(reopened.open(dbPath));
    QCOMPARE(reopened.count(), cap);
}

QTEST_MAIN(TestScanHistory)
#include "tst_scanhistory.moc"
