#include "qrdecoder.h"

#include <QUrl>

QrDecoder::QrDecoder(QObject* parent)
    : QObject(parent)
{
}

void QrDecoder::handleDecodedText(const QString& text)
{
    const QString trimmed = text.trimmed();
    const QUrl candidate = QUrl::fromUserInput(trimmed);

    if (candidate.isValid() && (candidate.scheme() == "http" || candidate.scheme() == "https")) {
        emit urlDetected(candidate.toString());
    } else {
        emit textDetected(trimmed);
    }
}
