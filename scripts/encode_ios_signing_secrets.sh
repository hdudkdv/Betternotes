#!/usr/bin/env bash
# Encode Apple signing files for GitHub Actions secrets.
#
# Usage (macOS / Linux / Git Bash):
#   ./scripts/encode_ios_signing_secrets.sh path/to/Certificates.p12 path/to/Profile.mobileprovision
#
# Output:
#   - build/signing/BUILD_CERTIFICATE_BASE64.txt
#   - build/signing/BUILD_PROVISION_PROFILE_BASE64.txt
# Copy each file's contents into the matching GitHub secret.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <certificate.p12> <profile.mobileprovision>"
  exit 1
fi

CERT_PATH="$1"
PROFILE_PATH="$2"

if [[ ! -f "$CERT_PATH" ]]; then
  echo "Certificate not found: $CERT_PATH"
  exit 1
fi

if [[ ! -f "$PROFILE_PATH" ]]; then
  echo "Provisioning profile not found: $PROFILE_PATH"
  exit 1
fi

OUT_DIR="build/signing"
mkdir -p "$OUT_DIR"

base64 -i "$CERT_PATH" | tr -d '\n' > "$OUT_DIR/BUILD_CERTIFICATE_BASE64.txt"
base64 -i "$PROFILE_PATH" | tr -d '\n' > "$OUT_DIR/BUILD_PROVISION_PROFILE_BASE64.txt"

echo "Created:"
echo "  $OUT_DIR/BUILD_CERTIFICATE_BASE64.txt"
echo "  $OUT_DIR/BUILD_PROVISION_PROFILE_BASE64.txt"
echo
echo "Next:"
echo "  1) Paste BUILD_CERTIFICATE_BASE64.txt into GitHub secret BUILD_CERTIFICATE_BASE64"
echo "  2) Paste BUILD_PROVISION_PROFILE_BASE64.txt into GitHub secret BUILD_PROVISION_PROFILE_BASE64"
echo "  3) Use the P12 password you chose when exporting the .p12 (already set as P12_PASSWORD if you used the generated one)"
echo "  4) Set APPLE_TEAM_ID from https://developer.apple.com/account"
echo "  5) Create the App Store profile named exactly: BetterNotes App Store"
