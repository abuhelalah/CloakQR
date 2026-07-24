#pragma once

#include <QByteArray>
#include <QString>

// ECC levels matching libqrencode QRecLevel
enum class EccLevel {
    Low      = 0,  // QR_ECLEVEL_L — ~7% recovery
    Medium   = 1,  // QR_ECLEVEL_M — ~15% recovery
    Quartile = 2,  // QR_ECLEVEL_Q — ~25% recovery
    High     = 3   // QR_ECLEVEL_H — ~30% recovery
};

// Encode modes matching libqrencode QRencodeMode
enum class QrEncodeMode {
    Numeric      = 1,
    Alphanumeric = 2,
    Byte         = 4,
    Kanji        = 8
};

struct QrModuleMatrix {
    int               version  = 0;  // 1-40
    int               width    = 0;  // (version-1)*4 + 21
    QByteArray        modules;       // row-major, one byte per module (non-zero = dark)
};
