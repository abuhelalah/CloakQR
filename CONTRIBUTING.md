# Contributing to CloakQR

Thanks for your interest in CloakQR — a privacy-first, on-device QR scanner and
generator built with Qt 6 (C++/QML). Contributions of all kinds are welcome:
bug reports, fixes, features, translations, documentation, and reviews.

By participating you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Core principles

Keep these in mind for every contribution:

- **Privacy first.** All user data stays on the device. The application must
  make **no network calls** from C++ code, and must not add analytics,
  tracking, or telemetry.
- **On-device only.** Scanning, generation, and history are local. Use
  `QStandardPaths` for storage — never hard-code paths.
- **Security matters.** See [SECURITY.md](SECURITY.md) for the encryption
  contract. Never log decrypted payloads or passphrases.

## Getting started

### Prerequisites

- Qt 6 (6.11.x recommended) with the Qt Quick, Multimedia, and SQL modules
- A C++17 toolchain and CMake ≥ 3.21 (Ninja optional)

### Build

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_PREFIX_PATH="/path/to/Qt/6.x/gcc_64"
cmake --build build --parallel
```

### Run the tests

Unit tests live under `tests/unit/` and can be built without a full Qt Quick
install:

```bash
cmake -S . -B build-tests -DBUILD_CLOAKQR_APP=OFF -DBUILD_TESTING=ON
cmake --build build-tests --parallel
ctest --test-dir build-tests --output-on-failure
```

Tests must not write to the real application data location — use a
`QTemporaryDir` or an in-memory SQLite database (`":memory:"`).

## Coding conventions

- **C++17** throughout; use `#pragma once`, `nullptr`, and `const` references
  for parameters that are not modified.
- Add `Q_OBJECT` to every `QObject` subclass that has signals or slots.
- Use `Q_INVOKABLE` for methods called directly from QML.
- Naming: `PascalCase` classes, `m_camelCase` members, `camelCase` locals,
  `kCamelCase` constants. File names are lowercase matching the class.
- Every `QAbstractListModel` subclass must implement `roleNames()`.

### QML

- Import only the modules a file actually uses.
- Prefer `ColumnLayout` / `RowLayout` and `Layout.fillWidth` over hard-coded
  pixel sizes and anchors for dynamic layouts.
- Wrap all user-visible strings in `qsTr()` so they can be translated.

### CMake

- Link Qt modules as `Qt6::<Module>`.
- Give each `add_library` matching `target_include_directories(... PUBLIC ...)`.
- Register test executables with `add_test(NAME … COMMAND …)`.

## Commit and pull-request guidelines

1. Fork the repository and create a topic branch from `main`.
2. Keep commits focused; write clear, imperative commit messages
   (e.g. "Add Wi-Fi payload validation").
3. Ensure the project builds and all tests pass before opening a PR.
4. Update `CHANGELOG.md` under **[Unreleased]** when your change is
   user-visible.
5. Describe what changed and why in the PR, and link any related issue.

## Reporting bugs and requesting features

Open an issue with:

- What you expected to happen and what actually happened
- Steps to reproduce, your platform, and the app version (see the About page)
- For crashes, any relevant (non-sensitive) log output

For security vulnerabilities, **do not** open a public issue — follow the
process in [SECURITY.md](SECURITY.md).

## Translations

User-facing strings use `qsTr()`; translation catalogs live under
`resources/i18n/`. New or updated translations are very welcome.

## License

By contributing, you agree that your contributions are licensed under the
project's [Mozilla Public License 2.0](LICENSE).
