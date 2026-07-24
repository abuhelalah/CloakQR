#pragma once

#include "qrtypes.h"

#include <QByteArray>
#include <QString>

// QrEncoder wraps libqrencode and converts a validated QrData payload into a
// QrModuleMatrix.  When CLOAKQR_ENABLE_VCPKG_DEPENDENCIES (or HAVE_LIBQRENCODE)
// is defined at compile time the real libqrencode path is used; otherwise the
// class compiles cleanly as a stub that returns an empty matrix.
class QrData;

class QrEncoder
{
public:
    QrEncoder() = default;

    // Encode the text carried by qrData and return the module matrix.
    // Returns a matrix with version == 0 on failure.
    QrModuleMatrix encode(const QrData& qrData) const;

    // Convenience overload.
    QrModuleMatrix encode(const QString& text, EccLevel ecc = EccLevel::Medium) const;
};
