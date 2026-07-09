#include "appengine.h"

AppEngine::AppEngine(QObject* parent)
    : QObject(parent)
{
}

bool AppEngine::proUnlocked() const
{
#ifdef ENABLE_PLAY_BILLING
    return m_proUnlocked;
#else
    return true;
#endif
}

void AppEngine::setProUnlocked(bool value)
{
    if (m_proUnlocked == value)
        return;

    m_proUnlocked = value;
    emit proUnlockedChanged();
}
