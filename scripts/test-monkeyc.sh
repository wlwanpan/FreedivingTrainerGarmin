#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
bash "$root/scripts/gen-key.sh"
sdk="$(bash "$root/scripts/sdk.sh")"
device="${1:-fenix7}"
out="$root/bin/FreedivingTrainer-${device}-test.prg"
mkdir -p "$root/bin"

devices_dir="${CONNECTIQ_DEVICES:-$HOME/.Garmin/ConnectIQ/Devices}"
if [[ ! -d "$devices_dir/$device" ]]; then
  echo "Skipping Monkey C unit tests: device files for $device are not installed." >&2
  exit 0
fi

"$sdk/bin/monkeyc" \
  -f "$root/watch/monkey.jungle" \
  -d "$device" \
  -o "$out" \
  -y "$root/watch/developer_key.der" \
  -t \
  -w \
  -l 1
echo "Compiled tests to $out"
echo "Run them with: connectiq && monkeydo $out $device -t"
