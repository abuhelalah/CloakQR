#pragma once

#include <QObject>

class AppEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool proUnlocked READ proUnlocked WRITE setProUnlocked NOTIFY proUnlockedChanged)

public:
    explicit AppEngine(QObject* parent = nullptr);

    bool proUnlocked() const;
    void setProUnlocked(bool value);

signals:
    void proUnlockedChanged();

private:
    bool m_proUnlocked = false;
};
