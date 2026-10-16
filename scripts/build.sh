#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
bash "$root/scripts/gen-key.sh"
sdk="$(bash "$root/scripts/sdk.sh")"
device="${1:-fenix7}"
out="$root/bin/FreedivingTrainer-${device}.prg"
mkdir -p "$root/bin"

devices_dir="${CONNECTIQ_DEVICES:-$HOME/.Garmin/ConnectIQ/Devices}"
if [[ ! -d "$devices_dir/$device" ]]; then
  echo "Device files for $device are not in $devices_dir" >&2
  echo "Open the Connect IQ SDK Manager, download Devices, then retry." >&2
  echo "Linux/macOS default path: ~/.Garmin/ConnectIQ/Devices" >&2
  exit 2
fi

echo "SDK $sdk"
echo "Device $device"
"$sdk/bin/monkeyc" \
  -f "$root/watch/monkey.jungle" \
  -d "$device" \
  -o "$out" \
  -y "$root/watch/developer_key.der" \
  -w \
  -l 1
echo "Wrote $out"
