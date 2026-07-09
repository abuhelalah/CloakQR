#pragma once

#include <QObject>

class QrDecoder : public QObject
{
    Q_OBJECT

public:
    explicit QrDecoder(QObject* parent = nullptr);

    Q_INVOKABLE void handleDecodedText(const QString& text);

signals:
    void urlDetected(const QString& url);
    void textDetected(const QString& text);
};
