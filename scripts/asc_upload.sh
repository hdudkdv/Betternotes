#!/usr/bin/env bash
# Upload an IPA to App Store Connect. Normalizes API-key secrets (they are
# often swapped or wrapped) and tries altool, then iTMSTransporter.
set -euo pipefail

IPA=${1:-}
if [[ -z "$IPA" || ! -f "$IPA" ]]; then
  echo "Usage: $0 path/to/app.ipa"
  exit 1
fi

strip() {
  printf '%s' "$1" | tr -d '\r\n"'\'' '
}

KEY_ID=$(strip "${APP_STORE_CONNECT_API_KEY_ID:-}")
KEY_ID=${KEY_ID#AuthKey_}
KEY_ID=${KEY_ID%.p8}
ISSUER=$(strip "${APP_STORE_CONNECT_ISSUER_ID:-}")
TEAM=$(strip "${APPLE_TEAM_ID:-}")
KEY_BODY=$(printf '%s\n' "${APP_STORE_CONNECT_API_KEY:-}" | tr -d '\r')

if [[ "$KEY_ID" =~ ^[0-9a-fA-F-]{36}$ && "$ISSUER" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "Key ID looks like a UUID and issuer looks like a Key ID — swapping."
  tmp=$KEY_ID
  KEY_ID=$ISSUER
  ISSUER=$tmp
fi

if [[ "$ISSUER" =~ ^[A-Z0-9]{10}$ && "$ISSUER" == "$TEAM" ]]; then
  echo "Issuer ID is the Team ID. App Store Connect needs the Issuer UUID from Users and Access → Integrations → App Store Connect API."
fi

echo "Using key id length=${#KEY_ID} issuer length=${#ISSUER} pem=$(printf '%s' "$KEY_BODY" | grep -c 'BEGIN PRIVATE KEY' || true)"

write_key() {
  local path=$1
  mkdir -p "$(dirname "$path")"
  if printf '%s\n' "$KEY_BODY" | grep -q "BEGIN PRIVATE KEY"; then
    printf '%s\n' "$KEY_BODY" > "$path"
  else
    {
      echo "-----BEGIN PRIVATE KEY-----"
      printf '%s\n' "$KEY_BODY" | tr -d '\n' | fold -w 64
      echo
      echo "-----END PRIVATE KEY-----"
    } > "$path"
  fi
  chmod 600 "$path"
}

KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
write_key "$KEY_PATH"
write_key "$HOME/private_keys/AuthKey_${KEY_ID}.p8"
write_key "$PWD/private_keys/AuthKey_${KEY_ID}.p8"

if ! openssl pkey -in "$KEY_PATH" -noout 2>/dev/null; then
  echo "Private key PEM did not parse. The APP_STORE_CONNECT_API_KEY secret is not a valid .p8."
  exit 1
fi
echo "Private key PEM parsed."

jwt_status() {
  local kid=$1 iss=$2
  ASC_KEY_ID="$kid" ASC_ISSUER="$iss" ASC_KEY_PATH="$KEY_PATH" ruby - "$kid" <<'RUBY'
require "openssl"
require "base64"
require "json"
require "net/http"
require "uri"

def b64(data)
  Base64.urlsafe_encode64(data, padding: false)
end

def ecdsa_der_to_jose(der)
  asn1 = OpenSSL::ASN1.decode(der)
  r = asn1.value[0].value.to_s(2)
  s = asn1.value[1].value.to_s(2)
  r = ("\x00" * (32 - r.bytesize)) + r if r.bytesize < 32
  s = ("\x00" * (32 - s.bytesize)) + s if s.bytesize < 32
  r[-32, 32] + s[-32, 32]
end

key_id = ENV.fetch("ASC_KEY_ID")
issuer = ENV.fetch("ASC_ISSUER")
key = OpenSSL::PKey.read(File.read(ENV.fetch("ASC_KEY_PATH")))
header = b64({ alg: "ES256", kid: key_id, typ: "JWT" }.to_json)
now = Time.now.to_i
payload = b64({ iss: issuer, iat: now, exp: now + 1200, aud: "appstoreconnect-v1" }.to_json)
input = "#{header}.#{payload}"
der = key.sign(OpenSSL::Digest::SHA256.new, input)
jwt = "#{input}.#{b64(ecdsa_der_to_jose(der))}"
uri = URI("https://api.appstoreconnect.apple.com/v1/apps?limit=1")
req = Net::HTTP::Get.new(uri)
req["Authorization"] = "Bearer #{jwt}"
res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
warn "App Store Connect /v1/apps HTTP #{res.code}"
puts res.code
RUBY
}

STATUS=$(jwt_status "$KEY_ID" "$ISSUER" | tail -n 1)
if [[ "$STATUS" != "200" && "$KEY_ID" =~ ^[A-Z0-9]{10}$ && "$ISSUER" =~ ^[0-9a-fA-F-]{36}$ ]]; then
  echo "Auth failed with current mapping; retrying swapped id/issuer."
  tmp=$KEY_ID
  KEY_ID=$ISSUER
  ISSUER=$tmp
  KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
  write_key "$KEY_PATH"
  write_key "$HOME/private_keys/AuthKey_${KEY_ID}.p8"
  write_key "$PWD/private_keys/AuthKey_${KEY_ID}.p8"
  STATUS=$(jwt_status "$KEY_ID" "$ISSUER" | tail -n 1)
fi

if [[ "$STATUS" != "200" ]]; then
  echo "App Store Connect rejected the API key (HTTP $STATUS)."
  echo "Create a new key: App Store Connect → Users and Access → Integrations → App Store Connect API → Generate API Key (Admin)."
  echo "Then set secrets APP_STORE_CONNECT_API_KEY_ID, APP_STORE_CONNECT_ISSUER_ID (the UUID at the top of that page), APP_STORE_CONNECT_API_KEY (full .p8)."
  exit 1
fi

echo "Uploading $IPA with altool"
if xcrun altool --upload-app --type ios --file "$IPA" --apiKey "$KEY_ID" --apiIssuer "$ISSUER"; then
  echo "altool upload succeeded"
  exit 0
fi

echo "altool failed; trying iTMSTransporter"
xcrun iTMSTransporter -m upload -assetFile "$IPA" -apiKey "$KEY_ID" -apiIssuer "$ISSUER" -v informational
echo "iTMSTransporter upload succeeded"
