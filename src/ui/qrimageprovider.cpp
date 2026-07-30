#include "qrimageprovider.h"

#include "qrgenerator.h"

#include <QColor>
#include <QUrl>

QrImageProvider::QrImageProvider(QrGenerator* generator)
    : QQuickImageProvider(QQuickImageProvider::Image)
    , m_generator(generator)
{
}

QImage QrImageProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
    // The id is "<percent-encoded payload>?e=<ecc>&f=<hex>&b=<hex>". The query
    // portion is optional so a bare payload still renders with the defaults.
    const int query = id.indexOf(QLatin1Char('?'));
    const QString encoded = query >= 0 ? id.left(query) : id;
    const QString text = QUrl::fromPercentEncoding(encoded.toUtf8());

    int ecc = 1;
    QColor foreground(Qt::black);
    QColor background(Qt::white);

    if (query >= 0) {
        const QStringList params = id.mid(query + 1).split(QLatin1Char('&'), Qt::SkipEmptyParts);
        for (const QString& param : params) {
            const int eq = param.indexOf(QLatin1Char('='));
            if (eq < 0)
                continue;
            const QString key = param.left(eq);
            const QString value = param.mid(eq + 1);
            if (key == QLatin1String("e"))
                ecc = value.toInt();
            else if (key == QLatin1String("f"))
                foreground = QColor(QStringLiteral("#") + value);
            else if (key == QLatin1String("b"))
                background = QColor(QStringLiteral("#") + value);
        }
    }

    const int target = requestedSize.isValid() ? qMax(requestedSize.width(), requestedSize.height())
                                               : 512;
    QImage image = m_generator->generateQr(text, ecc, target > 0 ? target : 512,
                                           foreground, background);

    if (size)
        *size = image.size();

    return image;
}
