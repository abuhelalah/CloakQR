#include "qrencoder.h"

#include <array>

namespace cloakqr {

namespace {

// --- Static specification tables (ISO/IEC 18004) --------------------------
//
// Rows are indexed by ECC level (Low, Medium, Quartile, High) and columns by
// version 1..40 (index 0 is an unused placeholder).

constexpr std::array<std::array<qint8, 41>, 4> kEccCodewordsPerBlock = {{
    // Low
    {{-1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30,
      28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
      30, 30, 30}},
    // Medium
    {{-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26,
      26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
      28, 28, 28}},
    // Quartile
    {{-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28,
      26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
      30, 30, 30}},
    // High
    {{-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28,
      26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
      30, 30, 30}},
}};

constexpr std::array<std::array<qint8, 41>, 4> kNumErrorCorrectionBlocks = {{
    // Low
    {{-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10,
      12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25}},
    // Medium
    {{-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17,
      18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49}},
    // Quartile
    {{-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23,
      23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68}},
    // High
    {{-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25,
      34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81}},
}};

// Alphanumeric character set; index within this string is the encoded value.
const char* const kAlphanumericCharset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";

enum class Mode { Numeric, Alphanumeric, Byte };

int eccIndex(QrEcc ecc)
{
    return static_cast<int>(ecc);
}

// 2-bit ECC indicator used in the 15-bit format information.
int eccFormatBits(QrEcc ecc)
{
    switch (ecc) {
    case QrEcc::Low: return 1;      // 0b01
    case QrEcc::Medium: return 0;   // 0b00
    case QrEcc::Quartile: return 3; // 0b11
    case QrEcc::High: return 2;     // 0b10
    }
    return 0;
}

bool getBit(long value, int index)
{
    return ((value >> index) & 1L) != 0;
}

// Total number of data-and-ECC modules available in a symbol of the given
// version, before removing format/version information.
int numRawDataModules(int version)
{
    int result = (16 * version + 128) * version + 64;
    if (version >= 2) {
        const int numAlign = version / 7 + 2;
        result -= (25 * numAlign - 10) * numAlign - 55;
        if (version >= 7)
            result -= 36;
    }
    return result;
}

// Number of 8-bit data codewords (excluding ECC) for a version/ECC pair.
int numDataCodewords(int version, QrEcc ecc)
{
    const int idx = eccIndex(ecc);
    const int totalCodewords = numRawDataModules(version) / 8;
    const int eccPerBlock = kEccCodewordsPerBlock[idx][version];
    const int numBlocks = kNumErrorCorrectionBlocks[idx][version];
    return totalCodewords - eccPerBlock * numBlocks;
}

int charCountBits(Mode mode, int version)
{
    int group; // 0: v1-9, 1: v10-26, 2: v27-40
    if (version <= 9)
        group = 0;
    else if (version <= 26)
        group = 1;
    else
        group = 2;

    switch (mode) {
    case Mode::Numeric: return (group == 0) ? 10 : (group == 1) ? 12 : 14;
    case Mode::Alphanumeric: return (group == 0) ? 9 : (group == 1) ? 11 : 13;
    case Mode::Byte: return (group == 0) ? 8 : 16;
    }
    return 8;
}

int modeIndicator(Mode mode)
{
    switch (mode) {
    case Mode::Numeric: return 0x1;
    case Mode::Alphanumeric: return 0x2;
    case Mode::Byte: return 0x4;
    }
    return 0x4;
}

int alphanumericValue(QChar ch)
{
    static const QString charset = QString::fromLatin1(kAlphanumericCharset);
    return charset.indexOf(ch);
}

Mode detectMode(const QString& text)
{
    bool allNumeric = !text.isEmpty();
    bool allAlnum = true;
    for (const QChar ch : text) {
        if (!ch.isDigit())
            allNumeric = false;
        if (alphanumericValue(ch) < 0)
            allAlnum = false;
    }
    if (allNumeric)
        return Mode::Numeric;
    if (allAlnum && !text.isEmpty())
        return Mode::Alphanumeric;
    return Mode::Byte;
}

// Number of pure data bits (excluding mode indicator and char-count indicator).
int dataBitLength(const QString& text, Mode mode, const QByteArray& utf8)
{
    switch (mode) {
    case Mode::Numeric: {
        const int n = text.size();
        return (n / 3) * 10 + ((n % 3 == 1) ? 4 : (n % 3 == 2) ? 7 : 0);
    }
    case Mode::Alphanumeric: {
        const int n = text.size();
        return (n / 2) * 11 + ((n % 2) ? 6 : 0);
    }
    case Mode::Byte:
        return utf8.size() * 8;
    }
    return utf8.size() * 8;
}

int charCount(const QString& text, Mode mode, const QByteArray& utf8)
{
    return (mode == Mode::Byte) ? utf8.size() : text.size();
}

// --- Bit buffer -----------------------------------------------------------

class BitBuffer
{
public:
    void appendBits(quint32 value, int length)
    {
        for (int i = length - 1; i >= 0; --i)
            m_bits.append(static_cast<quint8>((value >> i) & 1));
    }

    int size() const { return m_bits.size(); }

    QVector<quint8> toBytes() const
    {
        QVector<quint8> bytes(( m_bits.size() + 7) / 8, 0);
        for (int i = 0; i < m_bits.size(); ++i)
            bytes[i >> 3] |= static_cast<quint8>(m_bits[i] << (7 - (i & 7)));
        return bytes;
    }

private:
    QVector<quint8> m_bits;
};

// --- Reed-Solomon over GF(256), primitive polynomial 0x11D ----------------

quint8 gfMultiply(quint8 x, quint8 y)
{
    int z = 0;
    for (int i = 7; i >= 0; --i) {
        z = (z << 1) ^ ((z >> 7) * 0x11D);
        z ^= ((y >> i) & 1) * x;
    }
    return static_cast<quint8>(z);
}

QVector<quint8> reedSolomonDivisor(int degree)
{
    QVector<quint8> result(degree, 0);
    result[degree - 1] = 1;
    quint8 root = 1;
    for (int i = 0; i < degree; ++i) {
        for (int j = 0; j < degree; ++j) {
            result[j] = gfMultiply(result[j], root);
            if (j + 1 < degree)
                result[j] ^= result[j + 1];
        }
        root = gfMultiply(root, 0x02);
    }
    return result;
}

QVector<quint8> reedSolomonRemainder(const QVector<quint8>& data, const QVector<quint8>& divisor)
{
    QVector<quint8> result(divisor.size(), 0);
    for (const quint8 b : data) {
        const quint8 factor = b ^ result.front();
        result.removeFirst();
        result.append(0);
        for (int i = 0; i < result.size(); ++i)
            result[i] ^= gfMultiply(divisor[i], factor);
    }
    return result;
}

// --- Alignment pattern positions ------------------------------------------

QVector<int> alignmentPatternPositions(int version)
{
    if (version == 1)
        return {};
    const int numAlign = version / 7 + 2;
    const int step = (version == 32)
        ? 26
        : (version * 4 + numAlign * 2 + 1) / (numAlign * 2 - 2) * 2;
    const int size = version * 4 + 17;
    QVector<int> result;
    for (int i = 0, pos = size - 7; i < numAlign - 1; ++i, pos -= step)
        result.prepend(pos);
    result.prepend(6);
    return result;
}

// --- Symbol builder -------------------------------------------------------

class SymbolBuilder
{
public:
    SymbolBuilder(int version, QrEcc ecc)
        : m_version(version)
        , m_ecc(ecc)
        , m_size(version * 4 + 17)
        , m_modules(m_size * m_size, 0)
        , m_isFunction(m_size * m_size, 0)
    {
    }

    void draw(const QVector<quint8>& codewords)
    {
        drawFunctionPatterns();
        drawCodewords(codewords);
        m_mask = selectMask();
    }

    QrCode toQrCode() const
    {
        return QrCode(m_version, m_ecc, m_mask, m_size, m_modules, m_isFunction);
    }

private:
    int index(int x, int y) const { return y * m_size + x; }

    void setFunctionModule(int x, int y, bool isDark)
    {
        m_modules[index(x, y)] = isDark ? 1 : 0;
        m_isFunction[index(x, y)] = 1;
    }

    void drawFunctionPatterns()
    {
        for (int i = 0; i < m_size; ++i) {
            setFunctionModule(6, i, i % 2 == 0);
            setFunctionModule(i, 6, i % 2 == 0);
        }

        drawFinderPattern(3, 3);
        drawFinderPattern(m_size - 4, 3);
        drawFinderPattern(3, m_size - 4);

        const QVector<int> align = alignmentPatternPositions(m_version);
        const int n = align.size();
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < n; ++j) {
                const bool overlapsFinder = (i == 0 && j == 0)
                    || (i == 0 && j == n - 1)
                    || (i == n - 1 && j == 0);
                if (!overlapsFinder)
                    drawAlignmentPattern(align[i], align[j]);
            }
        }

        drawFormatBits(0); // reserved, overwritten after masking
        drawVersion();
    }

    void drawFinderPattern(int cx, int cy)
    {
        for (int dy = -4; dy <= 4; ++dy) {
            for (int dx = -4; dx <= 4; ++dx) {
                const int dist = qMax(qAbs(dx), qAbs(dy));
                const int x = cx + dx;
                const int y = cy + dy;
                if (x >= 0 && x < m_size && y >= 0 && y < m_size)
                    setFunctionModule(x, y, dist != 2 && dist != 4);
            }
        }
    }

    void drawAlignmentPattern(int cx, int cy)
    {
        for (int dy = -2; dy <= 2; ++dy)
            for (int dx = -2; dx <= 2; ++dx)
                setFunctionModule(cx + dx, cy + dy, qMax(qAbs(dx), qAbs(dy)) != 1);
    }

    void drawFormatBits(int mask)
    {
        const int data = (eccFormatBits(m_ecc) << 3) | mask;
        int rem = data;
        for (int i = 0; i < 10; ++i)
            rem = (rem << 1) ^ ((rem >> 9) * 0x537);
        const int bits = ((data << 10) | rem) ^ 0x5412;

        for (int i = 0; i <= 5; ++i)
            setFunctionModule(8, i, getBit(bits, i));
        setFunctionModule(8, 7, getBit(bits, 6));
        setFunctionModule(8, 8, getBit(bits, 7));
        setFunctionModule(7, 8, getBit(bits, 8));
        for (int i = 9; i < 15; ++i)
            setFunctionModule(14 - i, 8, getBit(bits, i));

        for (int i = 0; i < 8; ++i)
            setFunctionModule(m_size - 1 - i, 8, getBit(bits, i));
        for (int i = 8; i < 15; ++i)
            setFunctionModule(8, m_size - 15 + i, getBit(bits, i));
        setFunctionModule(8, m_size - 8, true); // always-dark module
    }

    void drawVersion()
    {
        if (m_version < 7)
            return;
        int rem = m_version;
        for (int i = 0; i < 12; ++i)
            rem = (rem << 1) ^ ((rem >> 11) * 0x1F25);
        const long bits = (static_cast<long>(m_version) << 12) | rem;

        for (int i = 0; i < 18; ++i) {
            const bool bit = getBit(bits, i);
            const int a = m_size - 11 + i % 3;
            const int b = i / 3;
            setFunctionModule(a, b, bit);
            setFunctionModule(b, a, bit);
        }
    }

    void drawCodewords(const QVector<quint8>& data)
    {
        int i = 0; // bit index
        for (int right = m_size - 1; right >= 1; right -= 2) {
            if (right == 6)
                right = 5;
            for (int vert = 0; vert < m_size; ++vert) {
                for (int j = 0; j < 2; ++j) {
                    const int x = right - j;
                    const bool upward = ((right + 1) & 2) == 0;
                    const int y = upward ? m_size - 1 - vert : vert;
                    if (!m_isFunction[index(x, y)] && i < data.size() * 8) {
                        m_modules[index(x, y)] = getBit(data[i >> 3], 7 - (i & 7)) ? 1 : 0;
                        ++i;
                    }
                }
            }
        }
    }

    void applyMask(int mask)
    {
        for (int y = 0; y < m_size; ++y) {
            for (int x = 0; x < m_size; ++x) {
                if (m_isFunction[index(x, y)])
                    continue;
                bool invert = false;
                switch (mask) {
                case 0: invert = (x + y) % 2 == 0; break;
                case 1: invert = y % 2 == 0; break;
                case 2: invert = x % 3 == 0; break;
                case 3: invert = (x + y) % 3 == 0; break;
                case 4: invert = (x / 3 + y / 2) % 2 == 0; break;
                case 5: invert = x * y % 2 + x * y % 3 == 0; break;
                case 6: invert = (x * y % 2 + x * y % 3) % 2 == 0; break;
                case 7: invert = ((x + y) % 2 + x * y % 3) % 2 == 0; break;
                }
                if (invert)
                    m_modules[index(x, y)] ^= 1;
            }
        }
    }

    int selectMask()
    {
        int bestMask = 0;
        long minPenalty = -1;
        for (int mask = 0; mask < 8; ++mask) {
            drawFormatBits(mask);
            applyMask(mask);
            const long penalty = penaltyScore();
            if (minPenalty < 0 || penalty < minPenalty) {
                minPenalty = penalty;
                bestMask = mask;
            }
            applyMask(mask); // undo
        }
        drawFormatBits(bestMask);
        applyMask(bestMask);
        return bestMask;
    }

    long penaltyScore() const
    {
        constexpr int kN1 = 3;
        constexpr int kN2 = 3;
        constexpr int kN3 = 40;
        constexpr int kN4 = 10;
        long result = 0;

        // Rule 1: runs of five or more same-color modules in rows and columns.
        for (int y = 0; y < m_size; ++y) {
            int runColor = -1;
            int runLen = 0;
            for (int x = 0; x < m_size; ++x) {
                const int c = m_modules[index(x, y)];
                if (c == runColor) {
                    ++runLen;
                    if (runLen == 5)
                        result += kN1;
                    else if (runLen > 5)
                        ++result;
                } else {
                    runColor = c;
                    runLen = 1;
                }
            }
        }
        for (int x = 0; x < m_size; ++x) {
            int runColor = -1;
            int runLen = 0;
            for (int y = 0; y < m_size; ++y) {
                const int c = m_modules[index(x, y)];
                if (c == runColor) {
                    ++runLen;
                    if (runLen == 5)
                        result += kN1;
                    else if (runLen > 5)
                        ++result;
                } else {
                    runColor = c;
                    runLen = 1;
                }
            }
        }

        // Rule 2: 2x2 blocks of the same color.
        for (int y = 0; y < m_size - 1; ++y) {
            for (int x = 0; x < m_size - 1; ++x) {
                const int c = m_modules[index(x, y)];
                if (c == m_modules[index(x + 1, y)]
                    && c == m_modules[index(x, y + 1)]
                    && c == m_modules[index(x + 1, y + 1)])
                    result += kN2;
            }
        }

        // Rule 3: finder-like 1:1:3:1:1 patterns with a 4-module light border.
        for (int y = 0; y < m_size; ++y)
            for (int x = 0; x <= m_size - 11; ++x)
                if (matchesFinderLike([&](int k) { return m_modules[index(x + k, y)]; }))
                    result += kN3;
        for (int x = 0; x < m_size; ++x)
            for (int y = 0; y <= m_size - 11; ++y)
                if (matchesFinderLike([&](int k) { return m_modules[index(x, y + k)]; }))
                    result += kN3;

        // Rule 4: deviation of dark-module proportion from 50%.
        int dark = 0;
        for (const quint8 m : m_modules)
            dark += m;
        const int total = m_size * m_size;
        const int k = (qAbs(dark * 20 - total * 10) + total - 1) / total - 1;
        result += static_cast<long>(k) * kN4;

        return result;
    }

    template <typename Getter>
    static bool matchesFinderLike(Getter at)
    {
        static const int patternA[11] = {1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0};
        static const int patternB[11] = {0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1};
        bool a = true;
        bool b = true;
        for (int k = 0; k < 11; ++k) {
            const int v = at(k);
            if (v != patternA[k])
                a = false;
            if (v != patternB[k])
                b = false;
        }
        return a || b;
    }

    int m_version;
    QrEcc m_ecc;
    int m_size;
    QVector<quint8> m_modules;
    QVector<quint8> m_isFunction;
    int m_mask = 0;
};

// Splits the data codewords into blocks, appends ECC and interleaves them.
QVector<quint8> addEccAndInterleave(const QVector<quint8>& data, int version, QrEcc ecc)
{
    const int idx = eccIndex(ecc);
    const int numBlocks = kNumErrorCorrectionBlocks[idx][version];
    const int blockEccLen = kEccCodewordsPerBlock[idx][version];
    const int rawCodewords = numRawDataModules(version) / 8;
    const int numShortBlocks = numBlocks - rawCodewords % numBlocks;
    const int shortBlockLen = rawCodewords / numBlocks;

    const QVector<quint8> divisor = reedSolomonDivisor(blockEccLen);

    QVector<QVector<quint8>> blocks;
    blocks.reserve(numBlocks);
    int k = 0;
    for (int i = 0; i < numBlocks; ++i) {
        const int datLen = shortBlockLen - blockEccLen + (i < numShortBlocks ? 0 : 1);
        QVector<quint8> block(data.begin() + k, data.begin() + k + datLen);
        k += datLen;
        const QVector<quint8> eccBytes = reedSolomonRemainder(block, divisor);
        if (i < numShortBlocks)
            block.append(0); // padding to equalise interleaving columns
        block.append(eccBytes);
        blocks.append(block);
    }

    QVector<quint8> result;
    result.reserve(rawCodewords);
    const int columns = blocks[0].size();
    for (int i = 0; i < columns; ++i) {
        for (int j = 0; j < blocks.size(); ++j) {
            if (i != shortBlockLen - blockEccLen || j >= numShortBlocks)
                result.append(blocks[j][i]);
        }
    }
    return result;
}

} // namespace

// --- QrCode ---------------------------------------------------------------

QrCode::QrCode(int version, QrEcc ecc, int mask, int size, QVector<quint8> modules,
               QVector<quint8> functionModules)
    : m_version(version)
    , m_ecc(ecc)
    , m_mask(mask)
    , m_size(size)
    , m_modules(std::move(modules))
    , m_functionModules(std::move(functionModules))
{
}

bool QrCode::module(int x, int y) const
{
    if (x < 0 || x >= m_size || y < 0 || y >= m_size)
        return false;
    return m_modules[y * m_size + x] != 0;
}

bool QrCode::isFunctionModule(int x, int y) const
{
    if (x < 0 || x >= m_size || y < 0 || y >= m_size)
        return false;
    return m_functionModules[y * m_size + x] != 0;
}

// --- QrEncoder ------------------------------------------------------------

int QrEncoder::byteModeCapacity(int version, QrEcc ecc)
{
    if (version < kMinVersion || version > kMaxVersion)
        return 0;
    const int capacityBits = numDataCodewords(version, ecc) * 8;
    const int overhead = 4 + charCountBits(Mode::Byte, version);
    const int available = capacityBits - overhead;
    return available > 0 ? available / 8 : 0;
}

int QrEncoder::minimumVersion(const QString& text, QrEcc ecc)
{
    const QByteArray utf8 = text.toUtf8();
    const Mode mode = detectMode(text);
    const int dataBits = dataBitLength(text, mode, utf8);

    for (int version = kMinVersion; version <= kMaxVersion; ++version) {
        const int capacityBits = numDataCodewords(version, ecc) * 8;
        const int needed = 4 + charCountBits(mode, version) + dataBits;
        if (needed <= capacityBits)
            return version;
    }
    return -1;
}

QrCode QrEncoder::encodeText(const QString& text, QrEcc ecc)
{
    const int version = minimumVersion(text, ecc);
    if (version < 0)
        return QrCode();

    const QByteArray utf8 = text.toUtf8();
    const Mode mode = detectMode(text);

    BitBuffer bb;
    bb.appendBits(modeIndicator(mode), 4);
    bb.appendBits(charCount(text, mode, utf8), charCountBits(mode, version));

    switch (mode) {
    case Mode::Numeric:
        for (int i = 0; i < text.size();) {
            const int take = qMin(3, text.size() - i);
            const int value = text.mid(i, take).toInt();
            bb.appendBits(value, take * 3 + 1);
            i += take;
        }
        break;
    case Mode::Alphanumeric:
        for (int i = 0; i < text.size();) {
            if (i + 1 < text.size()) {
                const int value = alphanumericValue(text[i]) * 45 + alphanumericValue(text[i + 1]);
                bb.appendBits(value, 11);
                i += 2;
            } else {
                bb.appendBits(alphanumericValue(text[i]), 6);
                i += 1;
            }
        }
        break;
    case Mode::Byte:
        for (const char c : utf8)
            bb.appendBits(static_cast<quint8>(c), 8);
        break;
    }

    const int capacityBits = numDataCodewords(version, ecc) * 8;
    const int terminator = qMin(4, capacityBits - bb.size());
    bb.appendBits(0, terminator);
    while (bb.size() % 8 != 0)
        bb.appendBits(0, 1);
    for (quint8 pad = 0xEC; bb.size() < capacityBits; pad = pad == 0xEC ? 0x11 : 0xEC)
        bb.appendBits(pad, 8);

    QVector<quint8> dataCodewords = bb.toBytes();
    const int expected = numDataCodewords(version, ecc);
    while (dataCodewords.size() < expected)
        dataCodewords.append(0);

    const QVector<quint8> interleaved = addEccAndInterleave(dataCodewords, version, ecc);

    SymbolBuilder builder(version, ecc);
    builder.draw(interleaved);
    return builder.toQrCode();
}

} // namespace cloakqr
