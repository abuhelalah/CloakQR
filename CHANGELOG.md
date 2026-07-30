# Changelog

All notable changes to CloakQR are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned

- Store publication after signing, device accessibility review, and maintainer approval.

### Added

- Separate Android paid edition (`com.abuhelalah.cloakqr.pro`) with no in-app
	billing dependency; Google Play can sell it as an independent application.
- Paid Logo Studio with bounded local image loading, adjustable logo coverage,
	forced ECC High, asynchronous composition, and ZXing readability validation.
- Paid Design Studio module/eye styling with safe gradients, optional logos, and
	mandatory ZXing validation of every final image.
- Paid Batch Studio with bounded UTF-8 CSV parsing, parallel ECC High PNG
	generation, deterministic filenames, progress, pause/resume, and cancellation.

### Changed

- Free edition entitlement is now locked at compile time and paid implementation
	and QML resources are excluded from the free APK.
- Removed the placeholder billing bridge and simulated purchase flow.
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
