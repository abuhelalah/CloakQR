# Changelog

All notable changes to CloakQR are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned

- Store publication after signing, device accessibility review, and maintainer approval.

## [1.1.0] - 2026-08-05

### Added

- Location QR generator now offers two input modes: **Coordinates** (latitude/longitude)
  and **Address** (street, building number, postal code, city, country).
- Scan result dialog shows a structured **To / Subject / Message** preview for email QR codes.
- Action buttons for email, SMS, maps, dialing, and contacts are now shown in the scan
  result dialog for every matching QR type.
- Desktop: "Send email" opens a real mail client (Thunderbird, Evolution, Geary, KMail,
  Mailspring, etc.) via `xdg-email`; the browser is only used as a last resort.

### Fixed

- All scan action buttons (Send email, Send message, Open in Maps, Dial, Add contact,
  Connect) were silently hidden due to a circular `visible` binding; they are now
  always shown for the matching QR type.
- MECARD contact QR codes are now correctly parsed alongside standard vCard payloads.

### Changed

- Compact navigation now uses a contextual app bar with previous/next arrows,
  an overflow page menu, and a focused four-control bottom navigation strip.

### Internationalization

- 30 new UI strings translated into English, Spanish, French, and Arabic (196 messages total).

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

[Unreleased]: https://github.com/abuhelalah/CloakQR/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/abuhelalah/CloakQR/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/abuhelalah/CloakQR/releases/tag/v1.0.0
