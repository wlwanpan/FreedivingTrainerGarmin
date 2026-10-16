# Build a Garmin connect IQ apps.

Using [Monkey C](https://developer.garmin.com/connect-iq/monkey-c/), build them with the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/), and document steps needed to submit it to Connect IQ Store.

The app is a stand alone app that can pair with an IOS app https://github.com/wlwanpan/FreedivingTrainer. Once paired and connected, all session performed on the app should be sync to the main IOS app. The aim is to build an equivalent of the main IOS app's target IOS watch but for Garmin watches instead.

The user installs the FreedivingTrainer app from the App Store, then installs the watch app from the Connect IQ Store onto a paired Garmin. Those two installs are linked only by an app UUID and Bluetooth, not by a shared bundle id.

The phone side is this existing app. Garmin’s [iOS companion SDK](https://github.com/garmin/connectiq-companion-app-sdk-ios) links into the iOS binary as a native module. On iOS it talks BLE directly to the watch. The user still needs Garmin Connect (or the Connect IQ Store app) to pair the watch and install updates.

## Sync, compared with the current watch bridge

The Apple Watch bridge in `targets/watch/session.swift` and `hooks/useWatchBridge.ts` has three channels:

| What moves | Apple Watch today | Garmin equivalent |
|---|---|---|
| Next table, language, settings | `updateApplicationContext` — latest snapshot, delivered when the watch app next runs | `sendMessage` from the iOS SDK to `Communications.registerForPhoneAppMessages`. Delivered while the watch app is open. A closed app can only catch a short background event. |
| Live heart rate and “table in progress” | `sendMessage` while the watch is reachable, plus a context refresh every 15 seconds | `Communications.transmit` while both apps are connected. Fine for a sample every few seconds. Stops if the iPhone app has been killed. |
| Finished table, queued if the phone is away | Saved in UserDefaults, then `sendMessage` with a saved-reply, falling back to `transferUserInfo`, which wakes the iPhone app | Saved in `Application.Storage`, then `transmit` when the phone app is reachable. Enabling Bluetooth LE background mode can wake the iPhone app, but that wake is less dependable than `transferUserInfo`. Retry the next time the user opens the watch app. |

A completion payload like the one built in `sendCompletion` — table type, rounds, timestamps, and a short heart-rate list — fits this channel. The whole plan schedule does not. Connect IQ heaps are small, so the phone should send the current session only.

Two Garmin sync paths do not land in this app’s SQLite. `ActivityRecording` writes a Garmin activity that syncs to Garmin Connect. `SyncDelegate` plus `makeWebRequest` uploads to a server during a Garmin Connect sync. This app keeps sessions on the device, so the companion BLE message is the path that matches the current bridge.

## What the watch app can run

A Connect IQ device app can run the table while it stays on screen: a one-second timer, a large clock, `Attention.vibrate` and `playTone` for phase changes, and `Sensor` heart rate. Heart rate comes from Garmin’s sensor. It becomes an Apple Health sample only if the iPhone app writes it after the payload arrives. The watch app cannot start an `HKWorkoutSession`.

If the user leaves the app, the timer stops. Background work is a short task, at most about every five minutes, with no vibration and no live heart rate. The table has to stay in the foreground for the whole session.

The UI is `WatchUi`, so the SwiftUI screens in `targets/watch/` do not carry over. Screens, memory, buttons, and vibration differ across Fenix, Forerunner, Venu, and Instinct, and each supported device is declared in the Connect IQ manifest.

## What it would take here

- A Monkey C project, built and submitted outside EAS.
- An Expo native module around `ConnectIQ.framework`, with the Bluetooth LE background mode, sharing the watch app’s UUID.
- A second store listing and a Garmin developer account.
- A slimmer sync protocol: current session down, completion with heart-rate samples up, retry from watch storage until the phone acknowledges it.

That is a second product with a similar session loop, not a second `targets/watch`. The timer and the completion record are realistic. Automatic install, HealthKit workouts, and guaranteed delivery while both apps are backgrounded are the parts the Apple Watch target has and Connect IQ does not.
