# expo-garmin-connect-iq

Expo native module that links [ConnectIQ.framework](https://github.com/garmin/connectiq-companion-app-sdk-ios) into the FreedivingTrainer iOS app. The watch app UUID is `a851fe4e-15ff-43a5-ba7b-6643c2b06a09`. The two store listings share that UUID and Bluetooth, not a bundle id.

## Add to FreedivingTrainer

1. Add this package to the iOS app workspace (path package or git URL).
2. Add the Garmin SPM package from `https://github.com/garmin/connectiq-companion-app-sdk-ios` so `import ConnectIQ` resolves.
3. Register the config plugin:

```js
plugins: [
  ['./companion/plugin/withGarminConnectIQ'],
]
```

The plugin turns on `bluetooth-central` background mode, the `freedivingtrainer` URL scheme, `gcm-ciq` query scheme, and Bluetooth usage strings.

4. On app start, call `initialize()`, then `showDeviceSelection()` once so Garmin Connect Mobile can share the paired watch. Handle the return URL with `handleOpenURL`.
5. Push the current session with `slimNextSession` + `sendNextSession`, and a live timer with `phoneTrainingMessage`. Do not send the weekly schedule. `wirePlanKey` hashes a `planKey` longer than 96 characters. This copy of the native module only forwards an explicit send. It does not cache a session and replay it when a watch pairs or sends `watchReady`. The module that ships is in the FreedivingTrainer iPhone app.
6. On `onMessage`, run `parseWatchMessage`. `watchReady` means the watch is open and still has no plan. The watch stamps `updatedAt` once per ask, reuses it if a transmit fails, and does not send another after that packet is delivered. Any handled `nextSession`, including tables only, stops the ask. Do not send the full session again on every 10s pulse. The shipping iPhone app sends tables when that `updatedAt` is newer than the last successful table delivery. Completions already use `watchDetail: "garmin"` and millisecond timestamps (the parser multiplies 32-bit Unix seconds from Connect IQ).
7. After SQLite save, send `buildAck(completedAt, syncedAt)` so the watch can drop the queued row.

## Background delivery

Bluetooth LE background mode can wake the iPhone app when the watch transmits. That wake is less reliable than Apple `transferUserInfo`. The watch retries from `Application.Storage` the next time it opens or receives a phone message.

## Not included

HealthKit workouts, automatic watch-app install, and guaranteed delivery while both apps are backgrounded. Those stay Apple Watch-only.
