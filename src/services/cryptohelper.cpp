#include "cryptohelper.h"

#include <QByteArray>
#include <QCryptographicHash>
#include <QMessageAuthenticationCode>
#include <QRandomGenerator>
#include <QStringList>

namespace {

constexpr auto kPayloadPrefix = "ENC:1:";
constexpr auto kKdfName = "pbkdf2-sha256";
constexpr int kPbkdf2Iterations = 200000;
constexpr int kSaltSize = 16;
constexpr int kNonceSize = 16;
constexpr int kDerivedKeySize = 64;
constexpr int kTagSize = 32;
constexpr int kHmacBlockSize = 32;

QByteArray encodeBase64Url(const QByteArray& value)
{
    return value.toBase64(QByteArray::Base64UrlEncoding | QByteArray::OmitTrailingEquals);
}

QByteArray decodeBase64Url(const QString& value, bool* ok)
{
    const QByteArray decoded = QByteArray::fromBase64(
        value.toLatin1(),
        QByteArray::Base64UrlEncoding);
    const bool valid = !value.isEmpty() && !decoded.isEmpty();

    if (ok)
        *ok = valid;

    return decoded;
}

QByteArray hmacSha256(const QByteArray& key, const QByteArray& message)
{
    return QMessageAuthenticationCode::hash(message, key, QCryptographicHash::Sha256);
}

QByteArray intToBigEndian(quint32 value)
{
    QByteArray out(4, Qt::Uninitialized);
    out[0] = static_cast<char>((value >> 24) & 0xff);
    out[1] = static_cast<char>((value >> 16) & 0xff);
    out[2] = static_cast<char>((value >> 8) & 0xff);
    out[3] = static_cast<char>(value & 0xff);
    return out;
}

QByteArray pbkdf2Sha256(const QByteArray& password, const QByteArray& salt, int iterations, int keyLength)
{
    QByteArray derived;
    const int blocks = (keyLength + kHmacBlockSize - 1) / kHmacBlockSize;

    for (int blockIndex = 1; blockIndex <= blocks; ++blockIndex) {
        QByteArray u = hmacSha256(password, salt + intToBigEndian(blockIndex));
        QByteArray t = u;

        for (int iteration = 1; iteration < iterations; ++iteration) {
            u = hmacSha256(password, u);
            for (int i = 0; i < t.size(); ++i)
                t[i] = static_cast<char>(t[i] ^ u[i]);
        }

        derived += t;
    }

    return derived.left(keyLength);
}

QByteArray keystream(const QByteArray& key, const QByteArray& nonce, int length)
{
    QByteArray stream;
    quint32 counter = 1;

    while (stream.size() < length) {
        stream += hmacSha256(key, nonce + intToBigEndian(counter));
        ++counter;
    }

    return stream.left(length);
}

QByteArray xorWithKeystream(const QByteArray& input, const QByteArray& key, const QByteArray& nonce)
{
    QByteArray output = input;
    const QByteArray stream = keystream(key, nonce, input.size());

    for (int i = 0; i < output.size(); ++i)
        output[i] = static_cast<char>(output[i] ^ stream[i]);

    return output;
}

QByteArray authenticationMessage(
    int iterations,
    const QByteArray& saltB64,
    const QByteArray& nonceB64,
    const QByteArray& ciphertextB64)
{
    return QByteArray("ENC:1:")
        + kKdfName + ':'
        + QByteArray::number(iterations) + ':'
        + saltB64 + ':'
        + nonceB64 + ':'
        + ciphertextB64;
}

bool constantTimeEqual(const QByteArray& left, const QByteArray& right)
{
    if (left.size() != right.size())
        return false;

    unsigned char diff = 0;
    for (int i = 0; i < left.size(); ++i)
        diff |= static_cast<unsigned char>(left[i] ^ right[i]);

    return diff == 0;
}

QByteArray randomBytes(int size)
{
    QByteArray out(size, Qt::Uninitialized);
    QRandomGenerator* generator = QRandomGenerator::global();

    for (int i = 0; i < size; ++i)
        out[i] = static_cast<char>(generator->generate() & 0xff);

    return out;
}

bool decodeFixedSizeField(const QString& value, int expectedSize, QByteArray* out)
{
    bool ok = false;
    const QByteArray decoded = decodeBase64Url(value, &ok);
    if (!ok || decoded.size() != expectedSize)
        return false;

    *out = decoded;
    return true;
}

}

CryptoHelper::CryptoHelper(QObject* parent)
    : QObject(parent)
{
}

QString CryptoHelper::encryptText(const QString& plainText, const QString& passphrase) const
{
    if (passphrase.isEmpty())
        return QString();

    const QByteArray plaintextBytes = plainText.toUtf8();
    const QByteArray salt = randomBytes(kSaltSize);
    const QByteArray nonce = randomBytes(kNonceSize);
    const QByteArray derivedKey = pbkdf2Sha256(passphrase.toUtf8(), salt, kPbkdf2Iterations, kDerivedKeySize);
    const QByteArray encryptionKey = derivedKey.left(kDerivedKeySize / 2);
    const QByteArray macKey = derivedKey.mid(kDerivedKeySize / 2);
    const QByteArray ciphertext = xorWithKeystream(plaintextBytes, encryptionKey, nonce);
    const QByteArray saltB64 = encodeBase64Url(salt);
    const QByteArray nonceB64 = encodeBase64Url(nonce);
    const QByteArray ciphertextB64 = encodeBase64Url(ciphertext);
    const QByteArray tag = hmacSha256(macKey, authenticationMessage(kPbkdf2Iterations, saltB64, nonceB64, ciphertextB64));

    return QString::fromLatin1(kPayloadPrefix)
        + QString::fromLatin1(kKdfName)
        + ':' + QString::number(kPbkdf2Iterations)
        + ':' + QString::fromLatin1(saltB64)
        + ':' + QString::fromLatin1(nonceB64)
        + ':' + QString::fromLatin1(ciphertextB64)
        + ':' + QString::fromLatin1(encodeBase64Url(tag));
}

QString CryptoHelper::decryptText(const QString& cipherText, const QString& passphrase) const
{
    if (passphrase.isEmpty())
        return QString();

    const QStringList parts = cipherText.split(':');
    if (parts.size() != 8)
        return QString();

    if (parts[0] != QStringLiteral("ENC") || parts[1] != QStringLiteral("1") || parts[2] != QString::fromLatin1(kKdfName))
        return QString();

    bool iterationsOk = false;
    const int iterations = parts[3].toInt(&iterationsOk);
    if (!iterationsOk || iterations <= 0)
        return QString();

    QByteArray salt;
    QByteArray nonce;
    QByteArray tag;
    if (!decodeFixedSizeField(parts[4], kSaltSize, &salt)
        || !decodeFixedSizeField(parts[5], kNonceSize, &nonce)
        || !decodeFixedSizeField(parts[7], kTagSize, &tag)) {
        return QString();
    }

    bool ciphertextOk = false;
    const QByteArray ciphertext = decodeBase64Url(parts[6], &ciphertextOk);
    if (!ciphertextOk && !parts[6].isEmpty())
        return QString();

    const QByteArray derivedKey = pbkdf2Sha256(passphrase.toUtf8(), salt, iterations, kDerivedKeySize);
    const QByteArray encryptionKey = derivedKey.left(kDerivedKeySize / 2);
    const QByteArray macKey = derivedKey.mid(kDerivedKeySize / 2);
    const QByteArray expectedTag = hmacSha256(
        macKey,
        authenticationMessage(iterations, parts[4].toLatin1(), parts[5].toLatin1(), parts[6].toLatin1()));

    if (!constantTimeEqual(tag, expectedTag))
        return QString();

    const QByteArray plaintextBytes = xorWithKeystream(ciphertext, encryptionKey, nonce);
    const QString plaintext = QString::fromUtf8(plaintextBytes);
    if (plaintext.toUtf8() != plaintextBytes)
        return QString();

    return plaintext;
}
