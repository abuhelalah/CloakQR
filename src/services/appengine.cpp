#include "appengine.h"

#include "cloakqr_version.h"

AppEngine::AppEngine(QObject* parent)
    : QObject(parent)
{
}

bool AppEngine::paidEdition() const
{
    return CLOAKQR_PAID_EDITION;
}

bool AppEngine::proUnlocked() const
{
    return paidEdition();
}

QString AppEngine::version() const
{
    return QStringLiteral(CLOAKQR_VERSION);
}
