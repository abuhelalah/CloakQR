#include <QtTest>

class TestQrGenerator : public QObject
{
    Q_OBJECT

private slots:
    void placeholder()
    {
        QVERIFY(true);
    }
};

QTEST_MAIN(TestQrGenerator)
#include "tst_qrgenerator.moc"
