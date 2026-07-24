#pragma once

#include <QQuickImageProvider>

class QrGenerator;

class QrImageProvider : public QQuickImageProvider
{
public:
    explicit QrImageProvider(QrGenerator* generator);

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;

private:
    QrGenerator* m_generator;
};
