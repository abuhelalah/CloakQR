#pragma once

#include <QObject>

class CryptoHelper : public QObject
{
    Q_OBJECT

public:
    explicit CryptoHelper(QObject* parent = nullptr);

    Q_INVOKABLE QString encryptText(const QString& plainText, const QString& passphrase) const;
    Q_INVOKABLE QString decryptText(const QString& cipherText, const QString& passphrase) const;
};
