#include "qrdata.h"

#include <QRegularExpression>

// Numeric:        digits 0-9
// Alphanumeric:   0-9, A-Z, space, $, %, *, +, -, ., /, :
// Byte:           arbitrary UTF-8

QrData::QrData(const QString& text, EccLevel ecc)
    : m_text(text)
    , m_ecc(ecc)
    , m_mode(detectMode(text))
{
    if (text.isEmpty()) {
        m_error = QStringLiteral("Input text must not be empty.");
        return;
    }

    const int maxBytes = capacityBytes();
    const int needed   = text.toUtf8().size();
    if (needed > maxBytes) {
        m_error = QStringLiteral("Input exceeds QR capacity: %1 bytes needed, %2 available.")
                      .arg(needed)
                      .arg(maxBytes);
    }
}

bool QrData::isValid() const
{
    return m_error.isEmpty();
}

QString QrData::errorString() const
{
    return m_error;
}

QrEncodeMode QrData::encodeMode() const
{
    return m_mode;
}

int QrData::capacityBytes() const
{
    switch (m_ecc) {
    case EccLevel::Low:      return kMaxBytesLow;
    case EccLevel::Medium:   return kMaxBytesMedium;
    case EccLevel::Quartile: return kMaxBytesQuartile;
    case EccLevel::High:     return kMaxBytesHigh;
    }
    return kMaxBytesMedium;
}

QrEncodeMode QrData::detectMode(const QString& text)
{
    static const QRegularExpression kNumeric      (QStringLiteral("^[0-9]+$"));
    static const QRegularExpression kAlphanumeric (QStringLiteral("^[0-9A-Z $%*+\\-./:]+$"));

    if (kNumeric.match(text).hasMatch())
        return QrEncodeMode::Numeric;

    if (kAlphanumeric.match(text).hasMatch())
        return QrEncodeMode::Alphanumeric;

    return QrEncodeMode::Byte;
}
