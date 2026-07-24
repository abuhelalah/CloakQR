#pragma once

#include "qrtypes.h"

#include <QFuture>
#include <QImage>
#include <QObject>
#include <QUrl>

class QrData;

class QrGenerator : public QObject
{
    Q_OBJECT

public:
    explicit QrGenerator(QObject* parent = nullptr);

    // Synchronous: render a QrModuleMatrix to a QImage at the given pixel size.
    // Each QR module is scaled to (pixelSize / matrix.width) pixels.
    Q_INVOKABLE QImage generateQr(const QString& text, int eccLevel = 1) const;

    // Asynchronous version — returns a QFuture<QImage> immediately.
    // Connect to QFutureWatcher<QImage>::finished to retrieve the result.
    QFuture<QImage> generateQrAsync(const QString& text, int eccLevel = 1) const;

    // Render a pre-computed matrix to QImage.
    static QImage renderMatrix(const QrModuleMatrix& matrix, int pixelSize = 512);

    // Render a matrix to a minimal SVG string.
    static QString renderSvg(const QrModuleMatrix& matrix, int moduleSize = 4);

    Q_INVOKABLE bool saveImage(const QImage& image, const QUrl& outputUrl) const;
};

