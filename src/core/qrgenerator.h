#pragma once

#include <QObject>
#include <QImage>
#include <QUrl>

class QrGenerator : public QObject
{
    Q_OBJECT

public:
    explicit QrGenerator(QObject* parent = nullptr);

    Q_INVOKABLE QImage generateQr(const QString& text, int eccLevel = 0) const;
    Q_INVOKABLE bool saveImage(const QImage& image, const QUrl& outputUrl) const;
};
