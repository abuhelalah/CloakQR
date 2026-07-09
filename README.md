# CloakQR

Privacy-first QR scanner and generator built with Qt 6 C++/QML.

## Current Shape

- Application code lives under `src/core`, `src/services`, `src/ui`, and `src/platform`.
- QML is split into `qml/common`, `qml/views`, and `qml/main.qml`.
- Public plugin interfaces live under `src/plugins`, with compile-time stubs in `src/plugins/stub`.
- Translations are staged under `resources/i18n` for English, Spanish, French, and Arabic.
- Unit tests live under `tests/unit`.
- Android package files live under `deploy/android`.

## Build Notes

- The repository can be configured with `BUILD_CLOAKQR_APP=OFF` to validate the unit-test slice independently of the full app target.
- The current unit targets are `tst_cryptohelper` and `tst_qrgenerator`.

## Status

This workspace is being aligned to the advanced plan in `PLAN.md`. The crypto helper and unit tests are already working in the isolated build configuration, while the rest of the QRGen feature set remains staged for later implementation.
