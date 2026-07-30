#include <QtTest>

#include "appengine.h"

class TestAppEngine : public QObject
{
    Q_OBJECT

private slots:
    void entitlementMatchesEdition()
    {
        AppEngine engine;
        QCOMPARE(engine.paidEdition(), bool(CLOAKQR_PAID_EDITION));
        QCOMPARE(engine.proUnlocked(), engine.paidEdition());
    }
};

QTEST_MAIN(TestAppEngine)
#include "tst_appengine.moc"