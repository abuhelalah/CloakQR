# CloakQR v1.0.0 Release Checklist

## Automated Gate

- [x] Linux Release build completes with `BUILD_CLOAKQR_APP=ON`.
- [x] All eight CTest suites pass, including QR decoding, release assets, and en/ar app startup.
- [x] Translation catalogs compile with no unfinished messages or placeholder drift.
- [x] Staged install contains `cloakqr`, `cloakqr_cli`, desktop entry, icon, and metadata.
- [x] Linux AppImage starts without host Qt libraries in the local packaged-runtime smoke test.
- [ ] Windows NSIS installer installs, launches, upgrades, and uninstalls correctly.
- [ ] Android release APK and AAB use `com.abuhelalah.cloakqr` and version `1.0.0`.
- [ ] SHA-256 checksums are recorded for every published artifact.

## Android Signing

Configure these protected GitHub Actions secrets:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded release keystore.
- `ANDROID_KEYSTORE_ALIAS`: release key alias.
- `ANDROID_KEYSTORE_PASSWORD`: keystore/key password.

Never commit the keystore, passwords, generated signing properties, or credentials.
Preserve an offline backup of the signing key; Play App Signing enrollment should
use a separate upload key when available.

## Manual Accessibility Gate

Test compact and expanded layouts in English and Arabic with font scales 100%,
150%, and 200%, light/dark themes, and high contrast enabled.

- [ ] Android TalkBack announces every actionable control with name, role, state, and order.
- [ ] Windows NVDA announces navigation, forms, generated preview, and dialogs correctly.
- [ ] Keyboard-only use reaches every action with visible focus and no traps.
- [ ] RTL navigation order, alignment, dialogs, and generated text remain coherent.
- [ ] Text does not clip or overlap at 200% scale on phone, tablet, and desktop widths.
- [ ] Contrast meets WCAG AA for normal text and controls.
- [ ] Reduced-motion/system animation settings do not block any workflow.

Record device/OS/screen-reader versions and attach screenshots or video to the
release issue. Automated startup tests do not replace this audit.

## Store Submission

- [ ] Confirm privacy policy URL and support contact.
- [ ] Capture current phone, tablet, Linux, and Windows screenshots.
- [ ] Verify store descriptions accurately describe on-device camera/image scanning.
- [ ] Complete Google Play Data safety accurately: no collection and no sharing.
- [ ] Submit signed AAB to an internal Play track before production rollout.
- [ ] Prepare F-Droid metadata and verify the recipe builds entirely from source.
- [ ] Publish the static site in `docs/` through GitHub Pages.
- [ ] Tag `v1.0.0`; confirm GitHub Actions attaches AppImage, archive, NSIS, APK, and AAB.
- [ ] Publish SHA-256 checksums and release notes from `CHANGELOG.md`.

GitHub, Google Play, F-Droid, and website publication require maintainer accounts
and cannot be considered complete until the resulting public URLs are verified.