# QR Generator App Development Plan — Final Version

This document defines the architecture, development phases, testing strategy, and release process for a cross‑platform QR Generator built with Qt6 C++/QML. It is the primary implementation guide from initial commit through the first paid release and beyond. All critical feedback has been integrated, and the plan now includes concrete multilingual support (en, es, fr, ar).

---

## 1. Free vs. Paid Features

| **Free (Open‑Source, MPL‑2.0)**                     | **Paid (One‑Time Purchase, Proprietary Extensions)**        |
|-----------------------------------------------------|-------------------------------------------------------------|
| QR codes for URL, Text, Email, Phone, SMS, WiFi, vCard, Geo‑location | All free formats + **Logo/image overlay** (centre icon)     |
| Basic styling: foreground/background colour, error correction L/M/Q/H | **Advanced customisation**: rounded modules, decorative eye styling, gradient fills |
| Save as PNG / SVG (single code)                     | **Batch generation** from **CSV** (well‑tested library)    |
| History of last 100 generated codes (JSON)           | **Export as PDF** — single & batch, configurable page size, margins, labels, multi‑code grids |
| Share image directly                                | **Import/export history** (seamless migration from free)    |
| No ads, no limits                                   | **Premium support** channel                                |
| **Command‑line interface (CLI)**                    | CLI extended with batch, PDF, and logo options               |
| Clear error message when content exceeds QR capacity | Estimated capacity guidance when logo is added              |
| **Opt‑in crash reporting** (disabled by default)    | Same                                                       |

The free version is genuinely useful for everyday and scripting needs; the paid version adds professional branding, bulk generation, advanced PDF output, and full CLI automation.

---

## 2. Development Phases & Timeline

| Phase                                 | Duration    | Outcome                                           |
|---------------------------------------|-------------|---------------------------------------------------|
| **1. Foundation & CI/CD**             | Weeks 1‑2   | Repository, build system, CI for all platforms    |
| **2. Core QR Engine**                 | Weeks 3‑4   | Robust encoding, validation, threading            |
| **3. Free App UI, Accessibility, i18n & CLI** | Weeks 5‑9   | Complete free version, ready for release          |
| **4. Free Release & Store Submissions**| Weeks 10‑13 | v1.0 on GitHub, Google Play, F‑Droid              |
| **5. Paid Features**                  | Weeks 14‑23 | Logo overlay (with estimated capacity + ZXing), CSV batch, PDF, styling, migration |
| **6. Free Update (Monthly Pop‑up)**   | Weeks 24‑25 | Pop‑up logic, v1.1 free app update                 |
| **7. Paid App Release**              | Weeks 26‑28 | Publish paid APK and desktop installers with licensing |
| **8. Polish & Maintenance (ongoing)** | Post‑release | Code signing, optional encryption, further UX refinements |

*Timeline based on a full‑time developer; adjust for part‑time availability.*

---

## 3. Folder Structure

```plaintext
QRGen/
├── CMakeLists.txt
├── README.md
├── LICENSE                          # MPL-2.0
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── CHANGELOG.md
├── .github/workflows/               # CI definitions
├── cmake/
│   └── dependencies.cmake           # vcpkg integration
├── src/
│   ├── core/                        # QR encoding, threading, data validation
│   │   ├── qrgenerator.h / .cpp     # Uses QtConcurrent::run() for async generation
│   │   ├── qrencoder.h / .cpp       # Wrapper around libqrencode
│   │   └── qrdata.h / .cpp          # Content validation, capacity checks, supported versions
│   ├── services/                    # History, settings, export/import, CLI, logging
│   │   ├── historymanager.h / .cpp  # JSON storage, 100 entries, privacy controls
│   │   ├── settings.h / .cpp        # Pop‑up scheduling, user prefs
│   │   ├── migrationhelper.h / .cpp # JSON export/import
│   │   ├── clicontroller.h / .cpp   # CLI (built on core)
│   │   └── logger.h / .cpp          # QLoggingCategory wrappers
│   ├── ui/                          # QML models, image provider, accessibility
│   │   ├── qrquickimageprovider.h / .cpp
│   │   ├── qrviewcontroller.h / .cpp
│   │   └── accessibilitymanager.h / .cpp
│   ├── platform/                    # OS abstractions (SAF, file dialogs, etc.)
│   │   └── platformutils.h / .cpp
│   ├── plugins/                     # Interface definitions (open‑source)
│   │   ├── plugininterface.h        # Base compile‑time plugin interface
│   │   ├── ilogooverlayplugin.h     # Virtual class for logo overlay
│   │   ├── ibatchgenerationplugin.h # Virtual class for batch generation
│   │   ├── ipdfexportplugin.h       # Virtual class for PDF export
│   │   └── stub/                    # Stub implementations (return "not available")
│   │       └── ...
│   ├── paid/                        # PAID – private repository only
│   │   ├── logooverlay.cpp          # Implements ILogoOverlayPlugin (estimated capacity, ZXing check)
│   │   ├── batchgenerator.cpp       # Implements IBatchGenerationPlugin, explicit QThreadPool, cancellation
│   │   ├── pdfexporter.cpp          # Implements IPdfExportPlugin using QPdfWriter (LGPL)
│   │   ├── advancedstyling.cpp      # Decorative eye styling, gradients (finder pattern structure never altered)
│   │   └── CMakeLists.txt
│   └── main.cpp                     # Application entry point
├── qml/
│   ├── common/
│   ├── views/
│   └── main.qml
├── resources/
│   ├── qml.qrc
│   ├── images/
│   └── i18n/                        # Translation files: en.ts, es.ts, fr.ts, ar.ts
├── tests/
│   ├── unit/
│   ├── integration/
│   └── ui/                          # Qt Quick Test‑based UI tests
├── deploy/
│   ├── android/
│   ├── windows/
│   └── linux/
└── scripts/
    └── ci_build.sh
```

*Critical notes*:
- `src/paid/` is **not** in the public repository. `BUILD_PAID=ON` expects a separate private repository checked out alongside the public repository and referenced through CMake. A `CMakeLists.txt` snippet checks for its existence and includes it if present.
- All paid features are compile‑time plugins, not runtime dynamic libraries.
- PDF export uses **QPdfWriter**, which is part of Qt’s QtGui module and available under LGPL (dynamic linking). No separate PDF library is required; if advanced features beyond QPdfWriter are needed in the future, a permissively‑licensed alternative can be integrated.

---

## 4. Versioning Strategy

Semantic Versioning (MAJOR.MINOR.PATCH) is followed. The initial free release is v1.0.0; the free update with pop‑up is v1.1.0; the paid version shares the same major.minor numbers where applicable.

---

## 5. Build System & Licensing

### 5.1 Project Licensing
- Open‑source code: **MPL‑2.0**.
- Paid extensions: **proprietary**, not distributed.
- External contributions accepted at maintainers’ discretion under MPL‑2.0.

### 5.2 Third‑Party Dependency Licenses

| Library      | License    | Usage                                                       |
|--------------|------------|-------------------------------------------------------------|
| libqrencode  | LGPL‑2.1   | QR matrix encoding                                          |
| ZXing‑C++    | Apache‑2.0 | QR decoding for logo readability verification               |
| CSV library  | (varies)   | Batch generation input parsing                              |
| QPdfWriter   | LGPL (via dynamic linking) | PDF export (part of QtGui, compatible with proprietary app when Qt is dynamically linked) |

*Note*: QPdfWriter is not GPL‑only. Under LGPL‑licensed Qt, it may be used in proprietary software provided the application dynamically links to Qt and complies with other LGPL obligations, which our packaging does.

### 5.3 Dependency Management
- vcpkg manifest with pinned versions of libqrencode, ZXing‑C++, and the chosen CSV library.

### 5.4 Build Variants
- `BUILD_PAID=OFF` (default): free app, stubs for paid plugins.
- `BUILD_PAID=ON`: expects a sibling private repository and includes it into the build via CMake.

### 5.5 Cross‑Platform Packaging & Code Signing

| Platform | Method                          | Notes                                                       |
|----------|---------------------------------|-------------------------------------------------------------|
| Linux    | AppImage via `linuxdeployqt`    | Dynamic Qt; optionally sign with GPG (v1.1).                |
| Windows  | NSIS installer + `windeployqt`  | Dynamic linking; sign binaries with **Authenticode** certificate (ideally for initial paid release, else fast‑follow) to avoid SmartScreen warnings. |
| Android  | Gradle + Qt for Android         | APK (free) / AAB (paid); no broad storage permission.       |

---

## 6. Development Standards & Conventions

### 6.1 Minimum Compiler Versions
C++20, GCC ≥ 12, Clang ≥ 15, MSVC 2022.

### 6.2 Performance Goals
- Single QR generation < 100 ms.
- UI never blocks (all heavy work on thread pool).
- Memory usage: single QR < few hundred KB; batch scales with available cores.
- Batch generation uses explicit `QThreadPool`. The default size is `QThread::idealThreadCount()`, but may be reduced for responsiveness or under memory pressure.

### 6.3 Error Handling Strategy
- User errors → friendly UI messages.
- Internal failures → logged via `QLoggingCategory`, UI shows generic error.
- Recoverable errors → graceful fallback with logging. For example, if history file is corrupted, the app renames the corrupted file, creates a fresh one, and notifies the user so they can attempt manual recovery.
- Fatal errors → exit with explanatory message.

### 6.4 Logging Categories
- `qrgen.core`, `qrgen.services`, `qrgen.ui`, `qrgen.platform`, `qrgen.plugins`.

### 6.5 Settings Keys (QSettings)
- `theme`, `defaultSaveDirectory`, `historyPath`, `lastPopupDate`, `language`, `recentExportDirectory`, `historyEnabled`, `historyExcludeWiFiPassword`, `activationToken` (paid desktop only – a signed activation blob, not the raw license key).

### 6.6 Release Build Configuration
- Max optimizations, LTO, stripped symbols, debug symbols kept separately.
- CI will build both Debug and Release configurations to catch LTO‑ and optimization‑specific issues.

### 6.7 Crash Reporting
- Opt‑in only, disabled by default. The user must explicitly enable crash reporting in the Settings. No data is sent without consent.

---

## 7. QR Encoding Standards & Capacity Rules

- libqrencode implements ISO/IEC 18004; all standard versions and error levels supported.
- Content exceeding a given version/level’s maximum is flagged with an explanation and a suggestion to shorten.
- **Logo overlay capacity guidance**: The application provides an **estimated capacity guidance** based on the selected error correction level and the configured logo size. Because real‑world readability also depends on mask pattern, logo shape, and scanner quality, the final QR code is always validated using ZXing‑C++ before export. If validation fails, the user is warned and export is blocked until adjustments are made.
- The logo area is restricted by a configurable constant: `constexpr double kMaxLogoCoverage = 0.15;` (15% of total QR area). This value can be tuned as testing and feedback dictate.
- **Decorative eye styling** refers to aesthetic modifications of the corner detection patterns (e.g., rounded corners, inner shapes). The functional structure (timing and position information) is **never altered**; scanners still recognise them correctly.

---

## 8. Privacy & History Handling

- History is stored as plain JSON in app‑private storage. A **privacy notice** is shown on first launch explaining local storage and potential sensitivity.
- **Sensitive fields**: For WiFi entries, the password field is **excluded from history by default** (controlled by `historyExcludeWiFiPassword`). A setting to **disable history entirely** or **clear on exit** is provided.
- A future update (v2) may add **optional AES‑256 encryption** with a user‑defined passphrase.

---

## 9. Paid Desktop Licensing (DRM)

For paid desktop versions (Windows/Linux), a lightweight license validation mechanism is implemented:

- **Offline public‑key signature**: The user receives a license key at purchase. On first launch, the app validates the key and replaces it with a signed **activation token** stored in QSettings. The raw key is not retained.
- **Activation only on first run**: Subsequent launches verify the activation token. Re‑validation occurs only on major version upgrades.
- **No online tracking**.
- **Key recovery**: A “Resend my license” form on the purchase website allows users to retrieve lost keys without repurchasing.

---

## 10. Batch Operation Cancellation & Progress

- The batch UI includes a **Cancel button** that sets an atomic flag; already‑started jobs finish, but no new jobs are dispatched. The UI also supports an optional **Pause/Resume** for large batches.
- Progress bar indicates completed / total items.

---

## 11. CLI Extensions for Paid Version

The CLI (available in free build) is extended in the paid build:

```
qrgen --batch-csv input.csv --output-dir ./out --format pdf --pdf-layout grid --pdf-labels
qrgen --text "Hello" --logo company.png --output qr.png
qrgen --wifi-ssid MyWiFi --wifi-password secret --logo logo.png --output wifi.png
```

Additionally, both free and paid CLI support reading input from stdin:

```
echo "Hello, world!" | qrgen --stdin --output qr.png
```

This is especially useful for Unix pipelines.

---

## 12. F‑Droid Specific Isolation

- The build flag `FDROID_BUILD` completely removes the **entire upgrade pop‑up UI component and its triggering logic** via preprocessor directives. No promotional code remains in the F‑Droid APK.
- The public source tree is structured so that the `UpgradeDialog.qml` file and related C++ code are easily excluded by the F‑Droid build recipe.
- The About page in F‑Droid builds displays a static, non‑promotional “Upgrade available” message with a link to the website.

---

## 13. UI Testing & Accessibility Audit

- **Automated UI smoke tests** using **Qt Quick Test** for core flows: generate, save, history list, settings persistence.
- An **accessibility audit** is a release gate: tested with NVDA on Windows, TalkBack on Android, and keyboard‑only navigation.

---

## 14. RTL Layout & Multilingual Support

- Qt’s `LayoutMirroring.enabled` is set based on the active translation locale.
- The initial release supports four languages: **English (en), Spanish (es), French (fr), and Arabic (ar)**. Translations are managed through Qt Linguist.
- RTL UI testing (Arabic) is included in the manual QA checklist to verify correct mirroring.

---

## 15. Detailed Phase Checklist

### Phase 1 – Foundation & CI/CD (Weeks 1‑2)
- [ ] Create public GitHub repository with README, .gitignore, MPL‑2.0 license, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CHANGELOG.md`.
- [ ] Set up vcpkg manifest with `libqrencode` and `ZXing‑C++` (pinned versions).
- [ ] Configure CMake to build all subdirectories (core, services, ui, platform, plugins, stub, tests, CLI).
- [ ] CI (GitHub Actions):
  - Build for Linux, Windows, Android (APK only – unit tests on desktop).
  - Linting: `clang‑tidy`, `clang‑format`.
  - Sanitizers on Linux debug builds.
  - Code coverage (lcov).
  - **Separate Debug and Release build jobs** to catch LTO/optimization issues.
  - Build with the latest Qt LTS and one newer Qt release.

### Phase 2 – Core QR Engine (Weeks 3‑4)
- [ ] Implement `QrEncoder` (libqrencode wrapper).
- [ ] Implement `QrData` with validation, capacity checks.
- [ ] Implement `QrGenerator` using `QtConcurrent::run()` for async generation.
- [ ] Unit tests: all data types, edge cases, SVG structural validation, QR version selection.
- [ ] Implement `QrQuickImageProvider` and `Logger`.

### Phase 3 – Free App UI, Accessibility, i18n & CLI (Weeks 5‑9)
- [ ] QML shell with StackView, dark/light theme, scalable fonts, RTL layout mirroring.
- [ ] Generator page: input, colour pickers, error correction, capacity warning, preview.
- [ ] Save/Share via SAF on Android, native dialogs elsewhere.
- [ ] History page with privacy settings (WiFi password exclusion, history disable/clear).
- [ ] Settings page with all keys defined.
- [ ] CLI with `--text`, `--wifi-ssid`, `--stdin`, etc.
- [ ] Accessibility: screen reader support, keyboard navigation, high‑contrast.
- [ ] Internationalisation: set up Qt Linguist, produce `.ts` files for **en, es, fr, ar**. Translate all visible strings.
- [ ] Performance profiling: <100 ms per QR generation.

### Phase 4 – Free Release & Store Submissions (Weeks 10‑13)
- [ ] Full test suite (including RTL UI tests, accessibility audit).
- [ ] Package: AppImage (Linux), NSIS installer (Windows), signed APK (Android).
- [ ] Publish on GitHub (v1.0.0), Google Play, F‑Droid.
- [ ] User documentation and website.

### Phase 5 – Paid Features Development (Weeks 14‑23)
*Private repository, `BUILD_PAID=ON`.*

- [ ] **Logo Overlay Plugin**: user‑resizable logo (up to kMaxLogoCoverage). Display estimated capacity guidance; enforce error correction H. Validate final QR with ZXing‑C++.
- [ ] **Decorative Eye Styling**: aesthetic modifications only, functional finder patterns untouched.
- [ ] **Batch Generation Plugin**: CSV parsing (lightweight library), explicit QThreadPool, cancellation/pause, progress.
- [ ] **PDF Export Plugin** using QPdfWriter; configurable page size, margins, labels, multi‑code grids.
- [ ] **Migration Helper**: JSON export/import.
- [ ] **CLI paid extensions**: `--batch-csv`, `--pdf-layout`, `--logo`, etc.
- [ ] Unit tests for capacity estimator, cancellation, PDF structure.

### Phase 6 – Free Update with Monthly Pop‑up (Weeks 24‑25)
- [ ] UpgradeDialog UI (non‑intrusive overlay). Trigger once per 30 days, stored in QSettings.
- [ ] F‑Droid build completely strips dialog via `FDROID_BUILD`.
- [ ] Release v1.1 on all channels.

### Phase 7 – Paid App Release (Weeks 26‑28)
- [ ] Implement offline activation token system.
- [ ] Build paid APK (different package ID), Windows/Linux installers.
- [ ] Sign Windows binaries if Authenticode certificate available (otherwise fast‑follow in Phase 8).
- [ ] Publish on Google Play; distribute desktop via Stripe/Gumroad.
- [ ] Update public README with migration guide.

### Phase 8 – Polish & Maintenance (ongoing)
- [ ] Windows code signing (if not done).
- [ ] GPG signature for AppImage.
- [ ] History encryption option.
- [ ] Refine translations, add more languages based on community.

---

## 16. Summary of All Enhancements

| Area                         | Implementation                                                                 |
|------------------------------|--------------------------------------------------------------------------------|
| PDF library                  | Uses QPdfWriter (LGPL, dynamic linking); no separate library needed.            |
| Logo capacity                | Estimated capacity guidance based on ECC and logo size, final ZXing validation. |
| Logo size limit              | Configurable `kMaxLogoCoverage` constant, default 15%, user can resize within.  |
| Finder pattern naming        | "Decorative eye styling" – functional information never changed.                |
| History privacy              | WiFi password excluded by default; disable/clear; corrupted file renamed.       |
| Paid licensing               | Offline activation token system; key recovery website.                         |
| Private repo integration     | Sibling private repository referenced via CMake.                                |
| Batch thread pool            | Default idealThreadCount(), can be reduced.                                     |
| Crash reporting              | Opt‑in, disabled by default.                                                    |
| Settings keys                | activationToken, not raw licenseKey.                                            |
| CLI                          | Added --stdin for pipe input.                                                   |
| CI                           | Debug + Release builds.                                                         |
| Languages                    | Initial support for en, es, fr, ar with Qt Linguist.                            |
| RTL layout                   | Tested with Arabic translations.                                                |
