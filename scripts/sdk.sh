#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
ciq_home="$(bash "$root/scripts/ciq-home.sh")"

sdk_candidates=(
  "${CONNECTIQ_SDK:-}"
  "$ciq_home/Sdks/current"
  /tmp/ciq-sdk
)

if [[ -n "${CONNECTIQ_SDK:-}" && -x "${CONNECTIQ_SDK}/bin/monkeyc" ]]; then
  echo "$CONNECTIQ_SDK"
  exit 0
fi

if [[ -f "$ciq_home/current-sdk.cfg" ]]; then
  cfg="$(tr -d '\r' < "$ciq_home/current-sdk.cfg")"
  if [[ -x "$cfg/bin/monkeyc" ]]; then
    echo "$cfg"
    exit 0
  fi
  parent="$(dirname "$cfg")"
  if [[ -x "$parent/bin/monkeyc" ]]; then
    echo "$parent"
    exit 0
  fi
fi

for candidate in "${sdk_candidates[@]}"; do
  if [[ -n "$candidate" && -x "$candidate/bin/monkeyc" ]]; then
    echo "$candidate"
    exit 0
  fi
done

shopt -s nullglob
for candidate in "$ciq_home"/Sdks/connectiq-sdk-*; do
  if [[ -x "$candidate/bin/monkeyc" ]]; then
    echo "$candidate"
    exit 0
  fi
done

echo "Connect IQ SDK not found. Install SDK 9.2.0 from https://developer.garmin.com/connect-iq/sdk/" >&2
echo "Then set CONNECTIQ_SDK to the unpacked SDK directory (the folder that contains bin/monkeyc)." >&2
exit 1
