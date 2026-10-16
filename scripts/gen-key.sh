#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
key="$root/watch/developer_key.der"
if [[ -f "$key" ]]; then
  echo "Using existing $key"
  exit 0
fi
openssl genrsa -out /tmp/freediving-garmin-key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
  -in /tmp/freediving-garmin-key.pem \
  -out "$key" \
  -nocrypt
rm -f /tmp/freediving-garmin-key.pem
echo "Wrote $key"
echo "Keep this key if you will publish to the Connect IQ Store. Garmin identifies your developer account by it."
