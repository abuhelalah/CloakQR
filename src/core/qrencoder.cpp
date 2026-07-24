#include "qrencoder.h"

#include "qrdata.h"
#include "logger.h"

#ifdef HAVE_LIBQRENCODE
#  include <qrencode.h>
#endif

QrModuleMatrix QrEncoder::encode(const QrData& qrData) const
{
    if (!qrData.isValid()) {
        Logger::warn("QrEncoder", qrData.errorString());
        return {};
    }

#ifdef HAVE_LIBQRENCODE
    const QByteArray utf8 = qrData.text().toUtf8();
    const int eccInt = static_cast<int>(qrData.eccLevel());

    QRcode* code = QRcode_encodeData(
        utf8.size(),
        reinterpret_cast<const unsigned char*>(utf8.constData()),
        0,                                      // version 0 = auto
        static_cast<QRecLevel>(eccInt));

    if (!code) {
        Logger::error("QrEncoder", QStringLiteral("libqrencode returned nullptr for: %1")
                          .arg(qrData.text().left(40)));
        return {};
    }

    QrModuleMatrix matrix;
    matrix.version = code->version;
    matrix.width   = code->width;

    const int total = code->width * code->width;
    matrix.modules.resize(total);
    for (int i = 0; i < total; ++i)
        matrix.modules[i] = static_cast<char>(code->data[i] & 1);

    QRcode_free(code);

    Logger::info("QrEncoder",
                 QStringLiteral("encoded version=%1 width=%2").arg(matrix.version).arg(matrix.width));
    return matrix;

#else
    // Stub: return a minimal placeholder so the build and tests work without libqrencode.
    Logger::info("QrEncoder", QStringLiteral("stub encode for: %1").arg(qrData.text().left(40)));

    // Build a trivial 21×21 (version-1) all-dark matrix as a visual placeholder.
    constexpr int kStubWidth = 21;
    QrModuleMatrix matrix;
    matrix.version = 1;
    matrix.width   = kStubWidth;
    matrix.modules.fill(static_cast<char>(1), kStubWidth * kStubWidth);
    return matrix;
#endif
}

QrModuleMatrix QrEncoder::encode(const QString& text, EccLevel ecc) const
{
    return encode(QrData(text, ecc));
}
