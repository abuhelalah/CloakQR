#include "qrimageprovider.h"

#include "qrgenerator.h"

#include <QUrl>

QrImageProvider::QrImageProvider(QrGenerator* generator)
    : QQuickImageProvider(QQuickImageProvider::Image)
    , m_generator(generator)
{
}

QImage QrImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    Q_UNUSED(requestedSize)

    const QString text = QUrl::fromPercentEncoding(id.toUtf8());
    QImage image = m_generator->generateQr(text);

    if (size)
        *size = image.size();

    return image;
}
