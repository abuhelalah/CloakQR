# Changelog

All notable changes to CloakQR are documented here. The project follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned

- Store publication after signing, device accessibility review, and maintainer approval.

## [2.0.0] - 2026-09-20

### Added

- **Biometric lock** (Android): optionally require fingerprint or face to open
  the app, with a Settings toggle and a full-screen gate on launch.
- **Share QR codes** (Android): send a generated QR to any app via the system
  share sheet (PNG handed over through a FileProvider).
- **Smart save filenames**: saving a QR now proposes a per-type default name
  (e.g. `url_example.png`, `wifi_MyNetwork.png`, `contact_name.png`), pre-filled
  and selected in the save dialog, with `.png` appended automatically and no
  silent overwriting.
- **Circular torch button** on the scanner, with a translucent-white ring.
- **History cap**: the on-device history keeps the newest 1,000 entries,
  silently evicting older ones so the local database stays bounded.

### Improved

- **Performance pass** (on-device):
  - Non-scanner pages now load lazily, and scan history loads asynchronously,
    so cold start no longer pays for pages the user hasn't opened.
  - QR generation, PNG save, Share, and the generator preview now run off the
    UI thread, keeping the UI responsive.
  - Scan-history display strings are precomputed, and rows are recycled while
    scrolling.
  - Live scanning decodes frames with a single pixel pass (luma-plane direct
    feed) and lighter decode hints, cutting per-frame CPU.
  - Release builds enable link-time optimization (LTO), and the unused Qt
    Widgets dependency was removed.
- **Large screens & edge-to-edge**: the Android portrait lock was removed so
  tablets and foldables rotate freely, and Android 15+ edge-to-edge insets are
  respected so content never sits under the status or navigation bars.
- Desktop sidebar now shows "Scan QR" for the scanner entry, matching the header.

### Fixed

- Android Share no longer fails to open the share sheet because of a file-path
  mismatch between the asynchronous save and the share handler.
- Icons in the scan-result dialog and history rows no longer disappear after
  the first open (a fragile icon-caching optimisation was reverted).
- The generator preview no longer renders as a black box on some devices and
  emulators.
- The scanner's "Choose image" button no longer overlaps the privacy badge,
  and the Create page's Save/Share buttons stay correctly placed at every
  window size.

### Changed

- Create page: "Save as PNG" is now simply "Save", matching the design.

### Internationalization

- New strings added to the English, Spanish, French, and Arabic catalogs;
  Arabic scan and delete wording was disambiguated (scan reads clearly, and
  delete/clear actions use "حذف" instead of the ambiguous "مسح").

## [1.2.2] - 2026-09-16

### Added

- Delete individual scan-history entries with a trash button on each row,
  instead of only being able to clear the whole list.
- Copy the generated QR content to the clipboard from the generator.

### Improved

- Scanner: video-frame conversion now runs off the UI thread, so the camera
  preview stays smooth while frames are prepared for decoding.
- Selected-image decoding no longer copies the image buffer (up to 32 MiB)
  before decoding.
- History entries now show the correct type icon for messaging, payment and
  calendar links (WhatsApp, Telegram, UPI, Bitcoin, VCALENDAR, etc.).

### Internationalization

- All new strings translated into English, Spanish, French, and Arabic.

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

[Unreleased]: https://github.com/abuhelalah/CloakQR/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/abuhelalah/CloakQR/compare/v1.2.2...v2.0.0
[1.2.2]: https://github.com/abuhelalah/CloakQR/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/abuhelalah/CloakQR/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/abuhelalah/CloakQR/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/abuhelalah/CloakQR/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/abuhelalah/CloakQR/releases/tag/v1.0.0
