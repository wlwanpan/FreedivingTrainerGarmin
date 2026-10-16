# expo-garmin-connect-iq

Expo native module that links [ConnectIQ.framework](https://github.com/garmin/connectiq-companion-app-sdk-ios) into the FreedivingTrainer iOS app. The watch app UUID is `0328696e-cb77-51ad-9d18-afcb600b4221`. The two store listings share that UUID and Bluetooth, not a bundle id.

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
5. Push the current session only with `slimNextSession` + `sendNextSession`, including when no Garmin is paired yet. Do not send the weekly schedule. The native module stores that payload and delivers it when a watch connects or the watch app sends `watchReady`.
6. On `onMessage`, run `parseWatchMessage`. Completions already use `watchDetail: "garmin"` and millisecond timestamps (the parser multiplies 32-bit Unix seconds from Connect IQ). If you see `watchReady`, send the current session again.
7. After SQLite save, send `buildAck(completedAt, syncedAt)` so the watch can drop the queued row.

## Background delivery

Bluetooth LE background mode can wake the iPhone app when the watch transmits. That wake is less reliable than Apple `transferUserInfo`. The watch retries from `Application.Storage` the next time it opens or receives a phone message.

## Not included

HealthKit workouts, automatic watch-app install, and guaranteed delivery while both apps are backgrounded. Those stay Apple Watch-only.
