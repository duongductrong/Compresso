# Local Sparkle Update Testing

Use this before first public update and before any signing/key migration.

## Prerequisites

- Sparkle private key file:

```bash
export SPARKLE_PRIVATE_KEY_FILE=$HOME/.config/droplit/sparkle_private_key.pem
```

- Stable self-signed signing identity:

```bash
./scripts/create-signing-cert.sh
```

Default identity: `Droplit Self-Signed`.

## Same-Cert Update Test

```bash
./scripts/test-update-local.sh test-same
```

Flow:

1. builds a release archive
2. creates local v99.0.0
3. installs v99.0.0 to `/Applications/Droplit.app`
4. creates local v99.0.1 DMG
5. signs the DMG with Sparkle EdDSA
6. serves appcast at `http://localhost:8089/appcast.xml`

Then open Droplit from `/Applications` and choose About -> Check for Updates.

Expected:

- update is discovered
- download starts
- install completes
- app relaunches as v99.0.1

## Signing-Mismatch Test

```bash
./scripts/test-update-local.sh test-mismatch
```

Default mismatch signs v2 ad-hoc. This is intentionally unsafe. Use it to confirm why release publish must block designated requirement drift.

Expected:

- update fails, or
- behavior is documented with logs before any migration override is allowed

## Cleanup

```bash
./scripts/test-update-local.sh clean
```

This removes `/tmp/test-droplit-sparkle-update` and stops the local server. It does not remove `/Applications/Droplit.app`.

## Notes

- Always run from `/Applications`, not the mounted DMG.
- Do not test with a private key committed into the repo.
- Do not rotate signing identity and Sparkle key in one release.

## Unresolved Questions

- None.
