#include "qrgenerator.h"

#include "qrdata.h"
#include "qrencoder.h"
#include "logger.h"

#include <QFile>
#include <QPainter>
#include <QtConcurrent/QtConcurrent>

QrGenerator::QrGenerator(QObject* parent)
    : QObject(parent)
{
}

QImage QrGenerator::generateQr(const QString& text, int eccLevel) const
{
    const EccLevel ecc = static_cast<EccLevel>(
        qBound(0, eccLevel, static_cast<int>(EccLevel::High)));

    QrEncoder encoder;
    const QrModuleMatrix matrix = encoder.encode(text, ecc);

    if (matrix.version == 0) {
        Logger::warn("QrGenerator", QStringLiteral("encode failed for text: %1").arg(text.left(40)));
        QImage blank(512, 512, QImage::Format_ARGB32_Premultiplied);
        blank.fill(Qt::white);
        return blank;
    }

    return renderMatrix(matrix);
}

QFuture<QImage> QrGenerator::generateQrAsync(const QString& text, int eccLevel) const
{
    return QtConcurrent::run([text, eccLevel]() -> QImage {
        QrGenerator gen;
        return gen.generateQr(text, eccLevel);
    });
}

QImage QrGenerator::renderMatrix(const QrModuleMatrix& matrix, int pixelSize)
{
    if (matrix.version == 0 || matrix.width == 0)
        return QImage();

    constexpr int kQuietZoneModules = 4;
    const int totalModules = matrix.width + kQuietZoneModules * 2;
    const int modulePixels = qMax(1, pixelSize / totalModules);
    const int imageSize    = totalModules * modulePixels;

    QImage image(imageSize, imageSize, QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::white);

    QPainter p(&image);
    p.setPen(Qt::NoPen);
    p.setBrush(Qt::black);

    const int offset = kQuietZoneModules * modulePixels;
    for (int row = 0; row < matrix.width; ++row) {
        for (int col = 0; col < matrix.width; ++col) {
            if (matrix.modules.at(row * matrix.width + col)) {
                p.drawRect(offset + col * modulePixels,
                           offset + row * modulePixels,
                           modulePixels, modulePixels);
            }
        }
    }
    p.end();

    return image;
}

QString QrGenerator::renderSvg(const QrModuleMatrix& matrix, int moduleSize)
{
    if (matrix.version == 0 || matrix.width == 0)
        return QString();

    constexpr int kQuietZoneModules = 4;
    const int totalModules = matrix.width + kQuietZoneModules * 2;
    const int svgSize      = totalModules * moduleSize;

    QString svg;
    svg.reserve(256 + matrix.modules.size() * 32);
    svg += QStringLiteral(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<svg xmlns=\"http://www.w3.org/2000/svg\""
        " version=\"1.1\""
        " viewBox=\"0 0 %1 %1\""
        " width=\"%1\" height=\"%1\">"
        "<rect width=\"%1\" height=\"%1\" fill=\"#ffffff\"/>")
               .arg(svgSize);

    const int offset = kQuietZoneModules * moduleSize;
    for (int row = 0; row < matrix.width; ++row) {
        for (int col = 0; col < matrix.width; ++col) {
            if (matrix.modules.at(row * matrix.width + col)) {
                svg += QStringLiteral("<rect x=\"%1\" y=\"%2\" width=\"%3\" height=\"%3\" fill=\"#000000\"/>")
                           .arg(offset + col * moduleSize)
                           .arg(offset + row * moduleSize)
                           .arg(moduleSize);
            }
        }
    }

    svg += QStringLiteral("</svg>");
    return svg;
}

bool QrGenerator::saveImage(const QImage& image, const QUrl& outputUrl) const
{
    const QString path = outputUrl.isLocalFile() ? outputUrl.toLocalFile() : outputUrl.toString();
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return false;

    const bool ok = image.save(&file, "PNG");
    file.close();
    return ok;
}

