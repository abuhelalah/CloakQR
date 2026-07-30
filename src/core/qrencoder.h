#pragma once

#include <QString>
#include <QVector>

namespace cloakqr {

// Error-correction levels as defined by ISO/IEC 18004.
enum class QrEcc {
    Low = 0,      // ~7% recovery
    Medium = 1,   // ~15% recovery
    Quartile = 2, // ~25% recovery
    High = 3      // ~30% recovery
};

// An immutable, fully-placed QR Code symbol.
//
// The matrix is stored row-major with one byte per module (1 = dark,
// 0 = light) and does not include the surrounding quiet zone.
class QrCode
{
public:
    QrCode() = default;
    QrCode(int version, QrEcc ecc, int mask, int size, QVector<quint8> modules,
           QVector<quint8> functionModules);

    bool isValid() const { return m_size > 0; }
    int version() const { return m_version; }
    QrEcc ecc() const { return m_ecc; }
    int mask() const { return m_mask; }

    // Number of modules per side (does not include the quiet zone).
    int size() const { return m_size; }

    // Returns true when the module at (x, y) is dark. Out-of-range
    // coordinates are treated as light so callers can query the quiet zone.
    bool module(int x, int y) const;
    bool isFunctionModule(int x, int y) const;

    const QVector<quint8>& modules() const { return m_modules; }
    const QVector<quint8>& functionModules() const { return m_functionModules; }

private:
    int m_version = 0;
    QrEcc m_ecc = QrEcc::Medium;
    int m_mask = -1;
    int m_size = 0;
    QVector<quint8> m_modules;
    QVector<quint8> m_functionModules;
};

// Stateless, standards-compliant QR Code encoder.
//
// The implementation is fully self-contained (no external dependency) so the
// privacy-first, offline build can generate codes without network or native
// packages. It supports numeric, alphanumeric and byte segments, automatically
// selecting the most compact single mode and the smallest fitting version.
class QrEncoder
{
public:
    // Encodes the given text at the smallest version (1..40) that fits for the
    // requested error-correction level. Returns an invalid QrCode when the
    // content cannot fit in a version-40 symbol.
    static QrCode encodeText(const QString& text, QrEcc ecc = QrEcc::Medium);

    // Maximum number of bytes encodable in byte mode for a version/ECC pair.
    static int byteModeCapacity(int version, QrEcc ecc);

    // Smallest version (1..40) that fits the text at the given ECC level, or
    // -1 when the content does not fit in any version.
    static int minimumVersion(const QString& text, QrEcc ecc);

    static constexpr int kMinVersion = 1;
    static constexpr int kMaxVersion = 40;
};

} // namespace cloakqr
