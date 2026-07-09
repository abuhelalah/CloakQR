# Security Policy

## Supported Scope

The repository is pre-release. Security fixes are accepted for the current default branch.

Areas that are especially security-sensitive:

- QR parsing and URL preview logic
- `ENC:1` payload parsing, key derivation, encryption, and integrity checks
- Local file export and import paths
- Android packaging, permissions, and billing-only build flags

## Reporting

Please report vulnerabilities privately to the maintainers before public disclosure.

Include the following when possible:

- affected file or feature
- impact summary
- proof-of-concept payload or reproduction steps
- whether the issue requires user interaction

Until a dedicated security contact is published, use the project maintainer channel and avoid posting exploit details in public issues first.

## Current Crypto Contract

The current implementation accepts only structured `ENC:1` payloads in this form:

`ENC:1:pbkdf2-sha256:<iterations>:<salt_b64url>:<nonce_b64url>:<ciphertext_b64url>:<tag_b64url>`

Expected behavior:

- wrong passphrases must fail closed
- tampered fields must fail closed
- malformed payloads must fail closed
- tag verification happens before plaintext is accepted

## Non-Goals For This Stage

- Backward compatibility with ad-hoc placeholder payloads from earlier scaffolding
- Claims of final production-hardening before the planned audited crypto dependency lands
- Recovery of data encrypted with an unknown passphrase
