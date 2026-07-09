# CloakQR Progress Log

## What Has Been Done So Far

The repository has been reorganized to match the new advanced plan layout.

- Created the plan-aligned directory skeleton under `src/core`, `src/services`, `src/ui`, `src/platform`, `src/plugins/stub`, `qml/common`, `qml/views`, `resources/i18n`, `tests/unit`, `tests/integration`, `tests/ui`, and `deploy/{android,windows,linux}`.
- Moved the existing QR engine and decoder sources into `src/core`.
- Moved the existing service-like sources into `src/services`.
- Moved the QML bindings into `src/ui`.
- Renamed the root QML entry file to `qml/main.qml` and split shared components into `qml/common` and feature views into `qml/views`.
- Moved the unit tests into `tests/unit` and added CMake targets for both `tst_cryptohelper` and `tst_qrgenerator`.
- Updated `CMakeLists.txt` to use the new folder structure and to expose the include paths needed by the moved sources.
- Kept the current implementation working for the crypto slice and verified both unit tests pass in the isolated build configuration.
- Removed the empty public `src/paid` directory so the repository matches the plan note that paid code lives outside the public tree.
- Added plan-aligned public plugin interface headers under `src/plugins` and stub placeholders in `src/plugins/stub`.
- Added empty translation scaffolds for `en`, `es`, `fr`, and `ar` under `resources/i18n`.
- Added a public plugin-stub README so the folder intent is explicit.
- Populated the top-level `README.md` with the current layout and build status.
- Wired the new `resources/qml.qrc` bundle and translation files into CMake so they are part of the configured project graph.
- Added `qmldir` metadata for `qml/common` and `qml/views`, and updated `qml/main.qml` to import `CloakQR.Common` and `CloakQR.Views` directly.

## Current State

- The repository now reflects the advanced plan’s folder organization much more closely than the earlier flat scaffold.
- The crypto helper still uses the interim authenticated `ENC:1` implementation that was added earlier.
- The free/pro split in the plan is still conceptual at the repository level; the paid private source tree is intentionally not present in this public workspace.
- The QML shell and unit-test layout are now aligned with the plan, but the broader QRGen feature set is still not fully implemented.
- The repository now also has the initial public plugin interfaces and translation placeholders expected by the plan.
- The resource bundle now includes the SVG logos and the translation files through `resources/qml.qrc`.
- The root QML shell now uses the shared header/footer components and the view module imports directly, which exercises the new QML layout instead of loading those files by path.

## Verified Recently

- `tst_cryptohelper` passes.
- `tst_qrgenerator` passes.
- The moved files compile correctly in the isolated `BUILD_CLOAKQR_APP=OFF` configuration.
