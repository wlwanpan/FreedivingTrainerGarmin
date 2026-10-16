#!/usr/bin/env bash
set -euo pipefail

sdk_candidates=(
  "${CONNECTIQ_SDK:-}"
  "${CONNECTIQ_HOME:-}"
  "$HOME/.Garmin/ConnectIQ/Sdks/current"
  /tmp/ciq-sdk
)

if [[ -n "${CONNECTIQ_SDK:-}" && -x "${CONNECTIQ_SDK}/bin/monkeyc" ]]; then
  echo "$CONNECTIQ_SDK"
  exit 0
fi

if [[ -f "$HOME/.Garmin/ConnectIQ/current-sdk.cfg" ]]; then
  cfg="$(tr -d '\r' < "$HOME/.Garmin/ConnectIQ/current-sdk.cfg")"
  if [[ -x "$cfg/bin/monkeyc" ]]; then
    echo "$cfg"
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
for candidate in "$HOME"/.Garmin/ConnectIQ/Sdks/connectiq-sdk-*; do
  if [[ -x "$candidate/bin/monkeyc" ]]; then
    echo "$candidate"
    exit 0
  fi
done

echo "Connect IQ SDK not found. Install SDK 9.2.0 from https://developer.garmin.com/connect-iq/sdk/" >&2
echo "Then set CONNECTIQ_SDK to the unpacked SDK directory (the folder that contains bin/monkeyc)." >&2
exit 1
