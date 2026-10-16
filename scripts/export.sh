#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
bash "$root/scripts/gen-key.sh"
sdk="$(bash "$root/scripts/sdk.sh")"
out="$root/bin/FreedivingTrainer.iq"
mkdir -p "$root/bin"

devices_dir="${CONNECTIQ_DEVICES:-$HOME/.Garmin/ConnectIQ/Devices}"
if [[ ! -d "$devices_dir" ]]; then
  echo "Connect IQ device files are missing at $devices_dir" >&2
  echo "The store .iq package needs a compiler.json for every product in watch/manifest.xml." >&2
  exit 2
fi

echo "Exporting store package with SDK $sdk"
"$sdk/bin/monkeyc" \
  -e \
  -r \
  -w \
  -f "$root/watch/monkey.jungle" \
  -o "$out" \
  -y "$root/watch/developer_key.der"
echo "Wrote $out"
echo "Upload this file in the Connect IQ Store app manager. See docs/CONNECT_IQ_STORE.md"
