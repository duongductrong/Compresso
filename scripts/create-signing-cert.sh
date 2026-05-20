#!/usr/bin/env bash
# Generate a self-signed code-signing certificate and print GitHub secret values.
# Usage: ./scripts/create-signing-cert.sh [cert_name] [validity_days]

set -euo pipefail

CERT_NAME="${1:-Droplit Self-Signed}"
VALIDITY_DAYS="${2:-3650}"

TEMP_DIR=$(mktemp -d)
KEYCHAIN_PATH="$TEMP_DIR/signing.keychain-db"
KEYCHAIN_PASSWORD=$(uuidgen)
P12_PATH="$TEMP_DIR/signing-cert.p12"

cleanup() {
  security delete-keychain "$KEYCHAIN_PATH" >/dev/null 2>&1 || true
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Droplit self-signed certificate generator"
echo "Certificate: $CERT_NAME"
echo "Validity days: $VALIDITY_DAYS"
echo

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychain -d user -s "$KEYCHAIN_PATH" $(security list-keychains -d user | tr -d '"')

cat > "$TEMP_DIR/cert.cfg" <<EOF
[ req ]
default_bits       = 2048
distinguished_name = req_dn
prompt             = no
x509_extensions    = codesign

[ req_dn ]
CN = $CERT_NAME
O  = Droplit

[ codesign ]
keyUsage         = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$TEMP_DIR/key.pem" \
  -out "$TEMP_DIR/cert.pem" \
  -days "$VALIDITY_DAYS" \
  -config "$TEMP_DIR/cert.cfg" \
  >/dev/null 2>&1

echo "Enter a password for the .p12 export:"
read -rs P12_PASSWORD
echo

if [ -z "$P12_PASSWORD" ]; then
  echo "Password cannot be empty" >&2
  exit 1
fi

openssl pkcs12 -export \
  -out "$P12_PATH" \
  -inkey "$TEMP_DIR/key.pem" \
  -in "$TEMP_DIR/cert.pem" \
  -passout "pass:$P12_PASSWORD" \
  >/dev/null 2>&1

security import "$P12_PATH" -P "$P12_PASSWORD" \
  -A -t cert -f pkcs12 -T /usr/bin/codesign \
  -k "$HOME/Library/Keychains/login.keychain-db" >/dev/null 2>&1 || true

security add-trusted-cert -d -r trustRoot -p codeSign \
  -k "$HOME/Library/Keychains/login.keychain-db" "$TEMP_DIR/cert.pem" >/dev/null 2>&1 || true

B64_CERT=$(base64 < "$P12_PATH" | tr -d '\n')

echo
echo "Add these GitHub secrets:"
echo
echo "SELF_SIGNED_CERT_P12"
echo "$B64_CERT"
echo
echo "SELF_SIGNED_CERT_PASSWORD"
echo "<the password entered above>"
echo
echo "Codesign identity: $CERT_NAME"
echo "If this is not the default name, set GitHub variable SELF_SIGNED_CODE_SIGN_IDENTITY to this value."
