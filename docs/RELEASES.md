# Release Workflow

Compresso uses Sparkle for in-app updates and GitHub Releases for DMG distribution.

## Release Shape

- Artifact: `Compresso-v<version>.dmg`
- Appcast: `appcast.xml`
- Feed URL: `https://raw.githubusercontent.com/duongductrong/Compresso/master/appcast.xml`
- Minimum macOS in appcast: `11.0`
- Sparkle package: `2.9.2`

## Required Secrets

- `SPARKLE_PRIVATE_KEY`
- `SELF_SIGNED_CERT_P12`
- `SELF_SIGNED_CERT_PASSWORD`
- `DEVELOPER_ID_P12`
- `DEVELOPER_ID_PASSWORD`
- `APPLE_ID`
- `APPLE_ID_PASSWORD`
- `APPLE_TEAM_ID`

Developer ID and Apple notarization secrets are optional until Apple Developer Program is available. `SPARKLE_PRIVATE_KEY` is mandatory for publishing Sparkle updates.

## Required Variables

- `ALLOW_ADHOC_RELEASE`
- `ALLOW_SIGNING_IDENTITY_CHANGE`
- `ALLOW_SPARKLE_KEY_CHANGE`

Keep all three false by default.

## Optional Variables

- `SELF_SIGNED_CODE_SIGN_IDENTITY`: self-signed certificate Common Name. Defaults to `Compresso Self-Signed`.

## Signing Policy

Preferred order:

1. Developer ID signed and notarized.
2. Stable self-signed certificate.
3. Ad-hoc only with explicit `ALLOW_ADHOC_RELEASE=true`.

Certificate continuity is a release gate. The publish workflow compares the candidate app designated requirement with the previous release. If it changes, publish fails unless `ALLOW_SIGNING_IDENTITY_CHANGE=true`.

Do not rotate the app signing identity and Sparkle EdDSA key in the same release. Self-signed to Developer ID migration is a separate migration release, not a normal patch.

## Prepare Release

Manual:

```bash
gh workflow run release-prepare.yml -f version_type=patch
```

Commit trigger:

```bash
git commit -m "release(patch): prepare next release"
git push origin master
```

The prepare workflow:

1. bumps `MARKETING_VERSION`
2. increments `CURRENT_PROJECT_VERSION`
3. updates `CHANGELOG.md`
4. opens or updates `release/vX.Y.Z`

## Publish Release

Merge the `release/vX.Y.Z` PR into `master`.

The publish workflow:

1. builds an unsigned archive
2. signs the app using the resolved signing strategy
3. verifies the app signature
4. checks signing continuity with previous release
5. creates `Compresso-vX.Y.Z.dmg`
6. notarizes when Apple credentials exist
7. signs the DMG with Sparkle EdDSA
8. creates the GitHub Release
9. prepends an appcast item
10. commits `appcast.xml` back to `master`

## Local Secret Setup

Generate a self-signed cert:

```bash
./scripts/create-signing-cert.sh
```

If you pass a custom cert name, set `SELF_SIGNED_CODE_SIGN_IDENTITY` to the same value before publishing.

The Sparkle private key used for the current public key was generated locally and exported to:

```bash
$HOME/.config/compresso/sparkle_private_key.pem
```

Add that file content as the `SPARKLE_PRIVATE_KEY` GitHub secret.

## Rollback

- Bad appcast metadata: fix `appcast.xml` and push.
- Bad EdDSA signature: re-sign the same DMG and update appcast signature.
- Broken release artifact: delete or mark release as broken, then publish a higher patch version.
- Certificate mismatch: do not publish. Restore old signing identity or create a dedicated migration plan.

## Unresolved Questions

- None.
