# CloakQR

CloakQR is an offline, privacy-first QR code generator built with Qt 6, C++17,
and QML. QR generation, settings, translations, and history storage stay on the
device. The application does not request internet access.

## Features

- Generate text, URL, email, phone, SMS, Wi-Fi, and location QR codes.
- Scan QR codes with a live camera or a selected image, entirely on-device.
- Export PNG images or generate PNG/SVG files from the command line.
- Choose error correction and foreground/background colours.
- Adaptive phone, tablet, and desktop layouts.
- Light, dark, high-contrast, scalable-text, keyboard, and RTL support.
- English, Spanish, French, and Arabic translations.
- Optional on-device history with Wi-Fi password exclusion and clear/disable controls.

The current `ENC:1` encrypted payload implementation is pre-audit; see
[SECURITY.md](SECURITY.md).

## Build

Requirements: CMake 3.21+, Ninja or Make, a C++17 compiler, and Qt 6 with Core,
Gui, Sql, Test, Concurrent, Multimedia, Quick, Qml, QuickControls2, Widgets, and
LinguistTools. CMake fetches the pinned ZXing-C++ reader during configuration.

```bash
qt-cmake -S . -B build -G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_CLOAKQR_APP=ON
cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

On systems with another Qt version in `/usr/lib`, place the selected Qt kit
first, for example:

```bash
export LD_LIBRARY_PATH=/opt/Qt/6.11.1/gcc_64/lib
```

To build only the reusable core, services, CLI, and unit tests:

```bash
qt-cmake -S . -B build-core -G Ninja -DBUILD_CLOAKQR_APP=OFF
cmake --build build-core --parallel
ctest --test-dir build-core --output-on-failure
```

## Command Line

```bash
cloakqr_cli --url https://example.com --output example.png --size 512
cloakqr_cli --wifi-ssid Home --wifi-password secret --ecc H --output wifi.svg
printf 'private text' | cloakqr_cli --stdin --format svg > code.svg
```

Run `cloakqr_cli --help` for all content types, colours, formats, and validation
options. Exactly one content source is accepted per invocation.

## Install And Package

```bash
cmake --install build --prefix "$PWD/stage"
cpack --config build/CPackConfig.cmake
```

Linux packaging supports AppImage output. Windows uses the CPack NSIS generator.
Android builds require the Qt Android arm64 kit, SDK, NDK, and JDK 17
installed. The tag-driven release workflow builds Linux, Windows, Android
APK/AAB, and GitHub release artifacts; signed Android output requires protected
repository secrets.

See [docs/release-checklist.md](docs/release-checklist.md) for signing, manual
accessibility checks, store submission requirements, and publication steps.

## Privacy And Security

- No telemetry or application-controlled network calls.
- Android backups and cleartext traffic are disabled.
- Sensitive history fields must be encrypted before storage.
- Authentication tags are compared in constant time.
- Imported and scanned content is untrusted until validated.

Security reports should follow [SECURITY.md](SECURITY.md). The detailed trust
boundaries are documented in [docs/threat-model.md](docs/threat-model.md).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md). CloakQR is licensed under MPL-2.0.
