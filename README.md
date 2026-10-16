# Freediving Trainer for Garmin

Connect IQ device app that runs CO2 and O2 breath-hold tables on a Garmin watch and syncs finished sessions to the [FreedivingTrainer](https://github.com/wlwanpan/FreedivingTrainer) iPhone app.

The user installs FreedivingTrainer from the App Store, then installs this app from the Connect IQ Store onto a paired Garmin. Those installs are linked only by an **app UUID** and Bluetooth, not by a shared bundle id.

| | |
|---|---|
| Application id | `0328696ecb7751ad9d18afcb600b4221` |
| Type | watch-app (Monkey C, Connect IQ 3.2+) |
| Companion | Expo native module around `ConnectIQ.framework` |
| iOS scheme | `freedivingtrainer` |

## What the watch does

- Standalone CO2 and O2 tables (same defaults as the iPhone app: 8 rounds, 90s CO2 hold / 60s O2 hold, 60s breathe-up).
- Current plan session from the phone when the watch app is open (`sendMessage` → `Communications.registerForPhoneAppMessages`).
- One-second timer, large clock, `Attention.vibrate` / `playTone` on phase changes, Garmin `Sensor` heart rate.
- Completion payload (`tableType`, rounds, timestamps, short heart-rate list) queued in `Application.Storage` and sent with `Communications.transmit` until the phone ACKs.

Keep the app on screen for the whole table. If the user leaves, the timer stops. Background Connect IQ work is a short task, at most about every five minutes, with no vibration and no live heart rate.

## Layout

```
watch/                 Monkey C project (manifest, jungle, source, resources)
companion/             Expo module + config plugin for the iOS app
scripts/               SDK build, store export, developer key
tests/                 Protocol, table, and session tests (Node)
docs/CONNECT_IQ_STORE.md
PROTOCOL.md
```

## Build the watch app

1. Install Java 11+ and [Connect IQ SDK 9.2.0](https://developer.garmin.com/connect-iq/sdk/).
2. In SDK Manager, download the SDK, set it active, and download Devices.
3. Generate a signing key once (`./scripts/gen-key.sh`) and keep it.
4. Store products compiled here: Descent G1 / G2 / Mk2 / Mk3 51mm, Epix 2, fēnix 7 / 8 Solar 47mm, Forerunner 965, Instinct 2, Venu 3. Descent G1 and Instinct 2 are 176×176 1-bit MIP (black/white UI). Descent G2 is 390×390 AMOLED. Add more ids in `watch/manifest.xml` after you download those device files.
5. Compile:

```bash
export CONNECTIQ_SDK=/path/to/unpacked/sdk
./scripts/build.sh descentg1
```

6. Simulator: `connectiq`, then `monkeydo bin/FreedivingTrainer-descentg1.prg descentg1`.

`npm test` runs the protocol tests without the SDK.

## iPhone companion

`companion/` wraps Garmin's [iOS companion SDK](https://github.com/garmin/connectiq-companion-app-sdk-ios). Wire it into FreedivingTrainer as a native module, enable Bluetooth LE background mode, and share the watch UUID. Details: [`companion/README.md`](companion/README.md) and [`PROTOCOL.md`](PROTOCOL.md).

The phone sends the **current session** only. The whole plan schedule does not fit Connect IQ heaps. Completions use `watchDetail: "garmin"` so they land in the existing SQLite `sessions` table.

## Connect IQ Store

This is a second store listing and needs a Garmin developer account. Step-by-step export and upload: [`docs/CONNECT_IQ_STORE.md`](docs/CONNECT_IQ_STORE.md).

```bash
./scripts/export.sh   # writes bin/FreedivingTrainer.iq
```

Upload that `.iq` at [apps.garmin.com/developer](https://apps.garmin.com/developer/). Do not upload a single-device `.prg`.
