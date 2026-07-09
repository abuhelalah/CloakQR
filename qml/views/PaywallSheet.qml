import QtQuick
import QtQuick.Controls

Dialog {
    id: paywall
    modal: true
    title: "Upgrade to Pro"

    Column {
        spacing: 10
        width: 320

        Label { text: "Unlock lifetime features" }
        Button { text: "Unlock Lifetime"; onClicked: billingBridge.purchasePro() }
        Button { text: "Restore Purchase"; onClicked: billingBridge.restorePurchases() }
    }
}
