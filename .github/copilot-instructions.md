# GitHub Copilot Instructions for CloakQR

## Project overview

CloakQR is a privacy-first QR scanner and generator built with **Qt 6 C++/QML**.
All user data stays on-device. There are no network calls from C++ code.

See `PLAN.md` for the full phased development roadmap and `SECURITY.md` for the
encryption contract.

---

## Language & standard

- **C++17** throughout (`CMAKE_CXX_STANDARD 17`).
- Use `#pragma once` — never `#ifndef` guards.
- Prefer `const` references for function parameters that are not modified.
- Use `nullptr` — never `NULL` or `0` for pointers.
- `Q_OBJECT` macro is required in every `QObject` subclass that emits signals or
  defines slots.

## Naming conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Classes | `PascalCase` | `ScanHistoryModel` |
| Member variables | `m_camelCase` | `m_entries` |
| Local variables | `camelCase` | `derivedKey` |
| Constants / `constexpr` | `kCamelCase` | `kSaltSize` |
| QML properties in C++ | `camelCase` (matches QML) | `proUnlocked` |
| Files | `lowercase` matching class | `scanhistorymodel.cpp` |

## Qt patterns

- Prefer `QStringList`, `QVector<T>`, `QHash<K,V>` over STL containers when
  interacting with Qt APIs.
- Use `Q_INVOKABLE` (not signals/slots) for methods called directly from QML.
- Use `QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)` to
  locate the on-device database and export paths — never hard-code paths.
- `QSqlDatabase` connections must be named; use `"cloakqr_<purpose>"` as the
  connection name to avoid collisions in tests.
- Every new `QAbstractListModel` subclass must implement `roleNames()` so that
  QML `ListView` delegates can reference roles by name.

## Security rules

- Never call `QString::fromUtf8(bytes)` and ignore the return value without
  verifying `toUtf8() == bytes` (UTF-8 round-trip check).
- Tag/MAC verification must use `constantTimeEqual` (already in `cryptohelper.cpp`).
  Do not use `==` to compare authentication tags.
- Encrypt before storing any sensitive user content to the database.
- Do not log decrypted payloads or passphrases.

## CMake

- Every new `add_library` target must have matching `target_include_directories`
  with `PUBLIC` scope so downstream targets can find its headers.
- Link Qt modules with `Qt6::<Module>` — never use the deprecated `Qt::<Module>`
  alias.
- Test executables must be registered with `add_test(NAME … COMMAND …)`.

## File exporter / CSV

- Quote every CSV field with double-quotes.
- Escape embedded double-quotes by doubling them (`""`).

## QML

- Import only the modules actually used in each file.
- Prefer `ColumnLayout` / `RowLayout` over anchors for dynamic layouts.
- Use `Layout.fillWidth: true` rather than hard-coded pixel widths.
- All user-visible strings should be wrapped in `qsTr()` to support future i18n.
- Image sources that use `QQuickImageProvider` use the `"image://<id>/"` URL
  scheme; the provider id must be registered in `main.cpp` before loading QML.

## Testing

- Unit-test files live under `tests/unit/` and are named `tst_<feature>.cpp`.
- Use `QTest::addColumn` / `QTest::newRow` for data-driven tests.
- Tests must not write to the real `AppDataLocation`; use `QTemporaryDir` or an
  in-memory SQLite path (`":memory:"`).
- The build must remain functional with `BUILD_CLOAKQR_APP=OFF` so the unit-test
  slice can be validated independently of a full Qt Quick install.
