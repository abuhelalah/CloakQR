# Changelog

All notable changes to CloakQR are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned

- Store publication after signing, device accessibility review, and maintainer approval.

### Changed

- Compact navigation now uses a contextual app bar with previous/next arrows,
	an overflow page menu, and a focused four-control bottom navigation strip.

## [1.0.0] - 2026-07-26

### Added

- Standards-compliant QR generation for text, URL, email, phone, SMS, Wi-Fi,
	vCard, and geographic payloads with ECC L/M/Q/H.
- On-device live-camera and selected-image QR scanning with Qt Multimedia and
	ZXing-C++, runtime camera permission, safe URL preview, and scan results.
- Asynchronous QML previews, PNG saving, SVG generation, and a full CLI.
- Adaptive compact, medium, and expanded layouts with light/dark themes,
	high contrast, scalable text, keyboard annotations, and Arabic RTL mirroring.
- English, Spanish, French, and Arabic catalogs with 132 translated messages each.
- On-device history and privacy settings.
- Linux desktop/AppStream metadata, Windows icon/NSIS configuration, Android
	launcher icons, stable application ID, and APK/AAB release automation.
- Release asset validation and English/Arabic headless application smoke tests.

### Security

- Disabled Android backup and cleartext traffic.
- Added authenticated `ENC:1` payload handling with constant-time tag verification.

### Known Limitations

- `ENC:1` is an interim pre-audit construction and should not be represented as
	independently audited cryptography.

[Unreleased]: https://github.com/abuhelalah/CloakQR/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/abuhelalah/CloakQR/releases/tag/v1.0.0
