# Submit Freediving Trainer to the Connect IQ Store

This watch app is a second store listing. It is not shipped through EAS. Users install FreedivingTrainer from the App Store, then install this app from the Connect IQ Store onto a paired Garmin. Garmin Connect (or the Connect IQ Store app) is still required to pair the watch and install updates.

Official Garmin references:

- [Submit an App](https://developer.garmin.com/connect-iq/submit-an-app/)
- [App review guidelines](https://developer.garmin.com/connect-iq/app-review-guidelines/)
- [SDK and developer agreement](https://developer.garmin.com/connect-iq/sdk/)
- Store manager: [https://apps.garmin.com/developer/](https://apps.garmin.com/developer/)

## 1. Garmin developer account

1. Create a Garmin account and join the Connect IQ developer program at [developer.garmin.com](https://developer.garmin.com/connect-iq/sdk/).
2. You must be 18 or older. Keep the account in good standing and do not share login credentials.
3. If the store username includes a company brand, you must be authorized to use that brand.

## 2. Keep one signing key

Garmin identifies you by the RSA key used to sign `.prg` / `.iq` files.

```bash
./scripts/gen-key.sh
```

That writes `watch/developer_key.der`. Back it up. Replacing it later makes Garmin treat you as a different developer. Do not commit the key (it is gitignored). The same key can sign sideload builds and store uploads.

## 3. SDK, devices, and a local build

1. Install Java 11+ and the [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/). Current compiler used here is **SDK 9.2.0**.
2. In the manager, download SDK 9.2.0, set it active, and download **Devices** for every product in `watch/manifest.xml`.
3. Install the Visual Studio Code **Monkey C** extension from Garmin and run `Monkey C: Verify Installation`.
4. Point the extension at this project:

```json
{
  "monkeyC.jungleFiles": "watch/monkey.jungle",
  "monkeyC.developerKeyPath": "watch/developer_key.der"
}
```

Device files live at `~/.Garmin/ConnectIQ/Devices` (Linux/macOS).

Compile one device:

```bash
export CONNECTIQ_SDK=/path/to/connectiq-sdk-lin-9.2.0-*
./scripts/build.sh fenix7
```

Sideload `bin/FreedivingTrainer-fenix7.prg` in the simulator (`connectiq`, then `monkeydo … fenix7`) or copy it to a watch. Test on at least one round device (fēnix / Forerunner) and one MIP device (Instinct / Descent) before you export.

## 4. Products and permissions in the manifest

`watch/manifest.xml` currently ships these products, all compiled in this repo:

- Descent Mk2, Descent Mk3 51mm
- Epix 2
- fēnix 7, fēnix 8 Solar 47mm
- Forerunner 965
- Instinct 2
- Venu 3

Add more `<iq:product>` rows (fēnix 6/7S/7X, Forerunner 255/265, vívoactive 5, Instinct 3, …) after you download those device files in SDK Manager. Then:

- `Communications` — phone companion BLE
- `Sensor` — Garmin optical heart rate

Add or remove `<iq:product>` rows before export. The store package fails if a product in the manifest has no device files on your machine. Do not add Edge cycling computers; this is a wrist timer.

`minApiLevel` is `3.2.0`.

## 5. Export the `.iq` package

The store wants one `.iq` that contains binaries for every supported product. A single-device `.prg` will be rejected.

From VS Code: **Monkey C: Export Project**, then Finish (Next only if you need to change languages).

From the command line:

```bash
./scripts/export.sh
```

That runs `monkeyc -e -r` and writes `bin/FreedivingTrainer.iq`. `-r` strips debug symbols for release.

## 6. First upload

1. Open [https://apps.garmin.com/developer/](https://apps.garmin.com/developer/).
2. Apps → Upload an App → type **Watch App**.
3. Upload `FreedivingTrainer.iq` (not the `.prg`).
4. After Garmin validates the binary, fill in the listing:

Suggested listing copy:

- **Name:** Freediving Trainer
- **Description:** Breath-hold tables on your Garmin. Run CO2 and O2 tables on the watch, or take the current session from the Freediving Trainer iPhone app. Completions sync to the phone over Bluetooth when the iPhone app is reachable. Keep the watch app on screen for the whole table; leaving it stops the timer.
- **Companion app:** iOS Freediving Trainer (`com.wlwanpan.FreedivingTrainer`). Link the App Store URL.
- **Privacy policy URL:** required if you collect user data. Heart rate is measured on the watch and sent to the iPhone app the user already installed. It is not uploaded to Garmin Connect by this app.
- Screenshots: home (plan / CO2 / O2), running hold with large clock, saved/sync screen. Capture them from the simulator (360×360 and a 416×416 round, plus a 176×176 Instinct-class MIP if you support it).
- Category: Training or Health & Fitness.
- Languages: English, French, Spanish, German, Korean (must match `watch/manifest.xml`).

## 7. Review

Garmin may review the app before it is public. You can preview and sideload your own listing while approval is pending. Typical review checks:

- The app launches on each declared product.
- Permissions match behavior (`Communications`, `Sensor`).
- Description matches what the app does. Do not imply a medical device or automatic HealthKit workout.
- Companion BLE is optional: the watch still runs default CO2/O2 tables offline.
- No Garmin trademark misuse in the name or icon.

Guidelines can change; reread [app-review-guidelines](https://developer.garmin.com/connect-iq/app-review-guidelines/) before each submission.

Once approved, the listing appears in the Connect IQ Store. Garmin assigns a **store UUID** for the listing. Keep the **application id** in `manifest.xml` unchanged. After the first approval, put the store UUID into the iOS `IQApp` `storeUuid` used by `companion/ios/GarminConnectIQModule.swift` (it currently reuses the application UUID, which is correct for sideload).

## 8. Updates

1. Bump the version in the VS Code export wizard (and keep a note in git).
2. Export a new `.iq` with the **same** application id and signing key.
3. App manager → Upload New Version → release notes.
4. Do not change the application UUID. That would orphan existing installs and break the iOS companion.

## 9. Pairing with the iPhone app

The user still needs Garmin Connect Mobile (or the Connect IQ Store app) to:

1. Pair the Garmin.
2. Install or update this watch app.
3. Hand the device list back to FreedivingTrainer through the `freedivingtrainer` URL scheme.

After that, the iPhone talks BLE directly through `ConnectIQ.framework`. See `companion/README.md`.
