#!/usr/bin/env bash
# Resolve the Connect IQ data directory (SDKs, device files, SDK Manager config).
set -euo pipefail

if [[ -n "${CONNECTIQ_HOME:-}" && -d "${CONNECTIQ_HOME}" ]]; then
  echo "$CONNECTIQ_HOME"
  exit 0
fi

for candidate in \
  "$HOME/Library/Application Support/Garmin/ConnectIQ" \
  "$HOME/.Garmin/ConnectIQ"; do
  if [[ -d "$candidate/Sdks" || -d "$candidate/Devices" ]]; then
    echo "$candidate"
    exit 0
  fi
done

echo "$HOME/.Garmin/ConnectIQ"
