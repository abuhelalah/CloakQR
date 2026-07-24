#pragma once

#include "qrtypes.h"

#include <QString>

// QrData validates the input text and selects encoding parameters before
// the actual QR symbol is generated.
class QrData
{
public:
    // Maximum byte capacity of a version-40 QR code at each ECC level.
    static constexpr int kMaxBytesLow      = 2953;
    static constexpr int kMaxBytesMedium   = 2331;
    static constexpr int kMaxBytesQuartile = 1663;
    static constexpr int kMaxBytesHigh     = 1273;

    explicit QrData(const QString& text, EccLevel ecc = EccLevel::Medium);

    // Returns false if text is empty or exceeds the capacity for the chosen ECC level.
    bool isValid() const;

    // Human-readable description of the last validation error, or empty on success.
    QString errorString() const;

    // Automatically selected encode mode for the given text.
    QrEncodeMode encodeMode() const;

    // Maximum byte capacity for the chosen ECC level.
    int capacityBytes() const;

    const QString& text()     const { return m_text; }
    EccLevel       eccLevel() const { return m_ecc; }

private:
    static QrEncodeMode detectMode(const QString& text);

    QString      m_text;
    EccLevel     m_ecc;
    QrEncodeMode m_mode;
    QString      m_error;
};
