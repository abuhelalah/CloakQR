#include <QImage>
#include <QProcess>
#include <QTemporaryDir>
#include <QtTest>

// Exercises the CLI executable end-to-end via QProcess. The path to the binary
// is injected at build time through the CLOAKQR_CLI_EXECUTABLE definition.
class tst_cli : public QObject
{
    Q_OBJECT

    QString runCli(const QStringList& args, int* exitCode, QByteArray* stdOut = nullptr)
    {
        QProcess proc;
        proc.start(QStringLiteral(CLOAKQR_CLI_EXECUTABLE), args);
        proc.waitForFinished(10000);
        if (exitCode)
            *exitCode = proc.exitCode();
        if (stdOut)
            *stdOut = proc.readAllStandardOutput();
        return QString::fromUtf8(proc.readAllStandardError());
    }

private slots:
    void generatesPng();
    void generatesSvgToStdout();
    void rejectsNoContent();
    void rejectsMultipleContent();
    void rejectsInvalidEcc();
};

void tst_cli::generatesPng()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString out = dir.filePath(QStringLiteral("code.png"));

    int code = -1;
    runCli({QStringLiteral("--url"), QStringLiteral("https://example.com"),
            QStringLiteral("--output"), out, QStringLiteral("--size"), QStringLiteral("256")},
           &code);

    QCOMPARE(code, 0);
    QVERIFY(QFileInfo::exists(out));
    const QImage image(out);
    QVERIFY(!image.isNull());
    QVERIFY(image.width() > 0);
}

void tst_cli::generatesSvgToStdout()
{
    int code = -1;
    QByteArray out;
    runCli({QStringLiteral("--text"), QStringLiteral("hello"),
            QStringLiteral("--format"), QStringLiteral("svg")},
           &code, &out);

    QCOMPARE(code, 0);
    QVERIFY(out.contains("<svg"));
    QVERIFY(out.contains("</svg>"));
}

void tst_cli::rejectsNoContent()
{
    int code = -1;
    runCli({}, &code);
    QCOMPARE(code, 2);
}

void tst_cli::rejectsMultipleContent()
{
    int code = -1;
    runCli({QStringLiteral("--text"), QStringLiteral("a"),
            QStringLiteral("--url"), QStringLiteral("https://b.com")},
           &code);
    QCOMPARE(code, 2);
}

void tst_cli::rejectsInvalidEcc()
{
    int code = -1;
    runCli({QStringLiteral("--text"), QStringLiteral("a"),
            QStringLiteral("--ecc"), QStringLiteral("Z"),
            QStringLiteral("--format"), QStringLiteral("svg")},
           &code);
    QCOMPARE(code, 2);
}

QTEST_GUILESS_MAIN(tst_cli)
#include "tst_cli.moc"
