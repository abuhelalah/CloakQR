# Threat Model

## Assets
- Scan history and future SQLite metadata.
- User-entered secrets and encrypted QR payloads.
- Lightweight local preferences and future purchase state.

## Trust Boundaries
- Camera and decoder input are untrusted.
- Imported QR text is untrusted until parsed and validated.
- The local device is partially trusted: data-at-rest can still leak through backups, screenshots, or rooted-device access.
- There is no app-controlled network trust boundary because the app is designed to run without `INTERNET` permission.

## Primary Threats
- Malicious QR content that tricks users into opening phishing URLs.
- Tampered encrypted payloads that attempt to bypass validation or trigger unsafe parsing.
- Weak passphrases that make offline guessing feasible after payload disclosure.
- Local disclosure through backups, device compromise, screen capture, or exported files.
- Dependency drift where crypto or scanner placeholders are mistaken for release-ready implementations.

## Current ENC:1 Format
- Prefix: `ENC:1:`
- Layout: `ENC:1:pbkdf2-sha256:<iterations>:<salt_b64url>:<nonce_b64url>:<ciphertext_b64url>:<tag_b64url>`
- KDF: PBKDF2-HMAC-SHA256
- Default iteration count in the current implementation: `200000`
- Salt length: 16 bytes
- Nonce length: 16 bytes
- Encryption: HMAC-SHA256-based stream keystream XOR, using a key derived from PBKDF2 output
- Integrity: HMAC-SHA256 over the canonical header and ciphertext fields using a separate derived key
- Encoding: Base64Url without padding for binary fields

## Validation Rules
- Reject payloads with the wrong prefix, version, field count, KDF label, or non-positive iteration count.
- Reject payloads whose salt, nonce, or tag fail Base64Url decoding or have unexpected lengths.
- Verify the HMAC tag before decrypting.
- Reject on tag mismatch, wrong passphrase, malformed UTF-8 plaintext, or field tampering.

## Security Notes
- This implementation is suitable for local authenticated payload handling during early development, but it is still below the target end-state described in the long-term plan.
- The release target remains a more standard construction with an audited AES or AEAD dependency once that source is vendored into the repository.
- No encrypted data should be described as unrecoverable against weak passphrases; offline guessing remains possible.
