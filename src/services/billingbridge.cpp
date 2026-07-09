#include "billingbridge.h"

BillingBridge::BillingBridge(QObject* parent)
    : QObject(parent)
{
}

void BillingBridge::purchasePro()
{
#ifdef ENABLE_PLAY_BILLING
    // TODO: implement JNI call to Google Play Billing.
#endif
    emit purchaseStateChanged(true);
}

void BillingBridge::restorePurchases()
{
#ifdef ENABLE_PLAY_BILLING
    // TODO: implement restore flow via Google Play Billing.
#endif
    emit purchaseStateChanged(false);
}
