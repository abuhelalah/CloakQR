#include "qrgenerator.h"

#include <QFile>
#include <QPainter>

QrGenerator::QrGenerator(QObject* parent)
    : QObject(parent)
{
}

QImage QrGenerator::generateQr(const QString& text, int eccLevel) const
{
    Q_UNUSED(eccLevel);

    QImage image(512, 512, QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::white);

    QPainter p(&image);
    p.setRenderHint(QPainter::Antialiasing, true);
    p.setPen(Qt::NoPen);
    p.setBrush(Qt::black);
    p.drawRect(32, 32, 448, 448);
    p.setBrush(Qt::white);
    p.drawText(image.rect(), Qt::AlignCenter, text.left(24));
    p.end();

    return image;
}

bool QrGenerator::saveImage(const QImage& image, const QUrl& outputUrl) const
{
    QFile file(outputUrl.toString());
    if (!file.open(QIODevice::WriteOnly))
        return false;

    const bool ok = image.save(&file, "PNG");
    file.close();
    return ok;
}
