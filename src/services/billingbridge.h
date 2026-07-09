#pragma once

#include <QObject>

class BillingBridge : public QObject
{
    Q_OBJECT

public:
    explicit BillingBridge(QObject* parent = nullptr);

    Q_INVOKABLE void purchasePro();
    Q_INVOKABLE void restorePurchases();

signals:
    void purchaseStateChanged(bool unlocked);
};
