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

After a save, also send:

```json
{ "type": "ack", "saved": true, "completedAt": 1700001000, "syncedAt": [1700001000] }
```

`slimNextSession` and `buildAck` in `companion/src/protocol.ts` build these payloads.

The phone should call `sendNextSession` whenever the current session changes, even if no Garmin is connected yet. The native module keeps the last payload and delivers it when a watch pairs or when the watch app opens.

## Watch → phone (`Communications.transmit` → `IQAppMessageDelegate`)

When the watch app opens (and while home still has no plan), it asks the phone for the current session:

```json
{ "type": "watchReady", "updatedAt": 1700000000 }
```

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
