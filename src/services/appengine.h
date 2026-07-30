#pragma once

#include <QObject>
#include <QString>

class AppEngine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool paidEdition READ paidEdition CONSTANT)
    Q_PROPERTY(bool proUnlocked READ proUnlocked CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)

public:
    explicit AppEngine(QObject* parent = nullptr);

    bool paidEdition() const;
    bool proUnlocked() const;
    QString version() const;
};
