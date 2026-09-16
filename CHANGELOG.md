# Changelog

All notable changes to CloakQR are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned

- Store publication after signing, device accessibility review, and maintainer approval.

## [1.2.1] - 2026-09-16

### Added

- Scan recognition for messaging and payment deep links: WhatsApp, Telegram,
  Signal, FaceTime, Messenger, Bitcoin, Ethereum, PayPal, and UPI QR codes now
  show a labelled action that opens the target app.
- Calendar (`VCALENDAR`) QR codes open the calendar app with the event
  pre-filled via an **Add to calendar** action (title, time, location and
  description are parsed from the payload).
- SEPA bank-transfer (`BCD`) QR codes are recognised and labelled.

### Improved

- QR type detection was refactored into a single, data-driven recogniser table,
  so adding a new scheme is a one-line change and classification runs in one pass.
- Scan actions now show "No app found to open this" when no handler is installed.
- The confirmation dialog is now centered on screen, and the clear-history button
  shows a live entry count and confirms deletion with that count.
- Arabic localization disambiguated: "scan" now reads "امسح ضوئياً" and
  clear/delete actions use "حذف" instead of the ambiguous "مسح".
- Language list reorders Arabic right after English.

### Internationalization

- All new strings translated into English, Spanish, French, and Arabic.

## [1.2.0] - 2026-08-31

### Added

- Scan support for two-factor `otpauth://` QR codes, with an **Add to
  authenticator** action that hands the code to Google Authenticator and other
  TOTP apps; account, issuer and code type are shown in a structured preview.
- Flashlight (torch) toggle on the live scanner, shown only when the camera
  reports flash support.
- **Paste** and **Clear** helpers in the generator for faster entry.

### Improved

- History entries are now tappable, reopening the full scan-result dialog with
  its quick actions; entries show type-specific icons (link, email, Wi-Fi,
  phone, SMS, location, contact, authenticator).
- Clearing scan history now asks for confirmation to prevent accidental deletes.
- QR preview generation is debounced and no longer re-encodes redundantly,
  reducing CPU/battery use while typing.

### Internationalization

- All new strings translated into English, Spanish, French, and Arabic.

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

[Unreleased]: https://github.com/abuhelalah/CloakQR/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/abuhelalah/CloakQR/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/abuhelalah/CloakQR/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/abuhelalah/CloakQR/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/abuhelalah/CloakQR/releases/tag/v1.0.0
