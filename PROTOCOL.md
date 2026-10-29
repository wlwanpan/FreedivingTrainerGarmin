# Garmin companion protocol

The watch and the iOS app share an application UUID and Bluetooth. They do not share a bundle id.

| | |
|---|---|
| Connect IQ application id | `a851fe4e15ff43a5ba7b6643c2b06a09` |
| UUID (dashed) | `a851fe4e-15ff-43a5-ba7b-6643c2b06a09` |
| iOS URL scheme | `freedivingtrainer` |
| `watchDetail` | `garmin` |

Garmin `Number` is 32-bit, so the watch sends Unix **seconds**. The Expo module promotes them to milliseconds before FreedivingTrainer's SQLite path (`readWatchCompletion`) sees them.

## Phone → watch (`ConnectIQ.sendMessage` → `Communications.registerForPhoneAppMessages`)

Delivered while the watch app is open. A closed app can only catch a short background event, so send the **current session only**. Do not send the weekly `schedule`.

```json
{
  "type": "nextSession",
  "name": "Week 1 · CO2",
  "tableType": "co2",
  "breatheUpSeconds": 60,
  "holdSeconds": 90,
  "restSeconds": 120,
  "rounds": [{ "hold": 90, "rest": 120 }],
  "week": 1,
  "sessionIndex": 1,
  "planKey": "beginner:1:",
  "planWeek": 1,
  "planWeeks": 6,
  "progress": 0,
  "planName": "Beginner",
  "language": "en",
  "trainingHaptic": true,
  "trainingSound": true,
  "phoneTraining": { "running": false },
  "loggedCount": 4,
  "sync": "",
  "syncedAt": [1700001000],
  "tables": {
    "breatheUpSeconds": 60,
    "co2": { "name": "CO2", "tableType": "co2", "holdSeconds": 90, "restSeconds": 120, "rounds": [] },
    "o2": { "name": "O2", "tableType": "o2", "holdSeconds": 60, "restSeconds": 120, "rounds": [] }
  }
}
```

Lock / complete variants set `locked: true` or `complete: true` and omit `rounds`.

`sync` is `""`, `"plan"`, or `"erase"`. `syncedAt` is completed-at **seconds** the phone has saved (the watch drops matching pending rows).

A live phone timer can arrive on its own, without the tables:

```json
{ "type": "phoneTraining", "running": true, "paused": false, "name": "CO2", "phase": "hold", "startedAt": 1700000000000 }
```

`running: false` clears that notice. The watch keeps `name` and draws it under the training-on-iPhone line. It clears `name` when `running` is false. It does not read `paused`, `phase`, or `startedAt`. On this message `startedAt` is epoch milliseconds. `phoneTrainingMessage` in `companion/src/protocol.ts` builds the payload.

`planKey` is opaque. `wirePlanKey` leaves a key of 96 characters or fewer unchanged. A longer key becomes `plan:` plus an FNV-1a 32-bit hex. The watch stores that string and echoes it on `sessionComplete`.

After a save, also send:

```json
{ "type": "ack", "saved": true, "completedAt": 1700001000, "syncedAt": [1700001000] }
```

`slimNextSession` and `buildAck` in `companion/src/protocol.ts` build the session and ack payloads. The iPhone app decides when to send them. The native module in this repo is a reference copy: it does not cache a `nextSession` and push it again when a watch pairs or when `watchReady` arrives. The module that ships is in the FreedivingTrainer iPhone app.

## Watch → phone (`Communications.transmit` → `IQAppMessageDelegate`)

The watch sends `watchReady` only while it still needs a phone plan: it is not running a table, not `locked`, not `complete`, and it has no current plan. `HomeView.onShow` is the only place that starts that ask.

```json
{ "type": "watchReady", "updatedAt": 1700000000 }
```

`updatedAt` is Unix seconds, chosen once for that ask. A retry after a failed transmit reuses the same value. After that packet is delivered, the watch does not send another until home is shown again and a plan is still missing. Any handled `nextSession` stops the 10 second timer, including a tables-only body (`tables` present, no slot `name` / `rounds`, and not `locked` or `complete`).

Do not send the full session on every `watchReady`. The shipping iPhone app sends the current tables when `updatedAt` is newer than the last successful table delivery. A repeat of the same `updatedAt` is the same ask.

A `watchReady` that is already queued or in flight is dropped. A queued `watchTraining` that has not started transmitting is replaced by the latest snapshot. `sessionComplete` and the packet already in flight are left alone.

The corner spinner runs while a transmit is in flight, and after a `sessionComplete` transmit succeeds until an `ack` or `syncedAt` list removes those rows. A successful `watchReady` does not keep the spinner up.

Live heart rate, about every 10 seconds while both apps are connected:

```json
{ "type": "heartRate", "bpm": 68, "at": 1700000500 }
```

Table in progress, on phase change and every 15 seconds:

```json
{
  "type": "watchTraining",
  "running": true,
  "paused": false,
  "name": "CO2",
  "phase": "Hold",
  "updatedAt": 1700000000,
  "pendingCount": 0,
  "startedAt": 1699999900
}
```

Finished table. Stored in `Application.Storage` until ACK. Cap 40 heart-rate samples.

```json
{
  "type": "sessionComplete",
  "tableType": "co2",
  "holdSeconds": 90,
  "restSeconds": 120,
  "roundsCompleted": 8,
  "roundsPlanned": 8,
  "startedAt": 1700000000,
  "completedAt": 1700001000,
  "source": "watch",
  "watchDetail": "garmin",
  "heartRates": [{ "bpm": 68, "at": 1700000500 }],
  "week": 1,
  "sessionIndex": 1,
  "planKey": "beginner:1:"
}
```

Plan slot fields are omitted for standalone CO2/O2 tables (`week` 0).

`parseWatchMessage` turns seconds into milliseconds and is safe to pass into FreedivingTrainer's existing `readWatchCompletion`.

## What this channel is not

`ActivityRecording` writes a Garmin activity that syncs to Garmin Connect. `SyncDelegate` plus `makeWebRequest` uploads during a Garmin Connect sync. Neither lands in FreedivingTrainer's SQLite. Companion BLE is the path that matches the Apple Watch bridge.
