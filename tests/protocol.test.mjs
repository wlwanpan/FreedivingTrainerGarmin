import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import {
  slimNextSession,
  parseWatchMessage,
  buildAck,
  toUnixMs,
  buildCo2Rounds,
  phoneTrainingMessage,
  wirePlanKey,
} from '../companion/src/protocol.ts'

describe('unix timestamps', () => {
  it('promotes Connect IQ 32-bit seconds to milliseconds', () => {
    assert.equal(toUnixMs(1700000000), 1700000000000)
  })

  it('keeps already-millisecond values', () => {
    assert.equal(toUnixMs(1700000000000), 1700000000000)
  })
})

describe('slim next session', () => {
  it('sends the current session and tables, not a weekly schedule', () => {
    const payload = slimNextSession({
      type: 'nextSession',
      name: 'Week 1 · CO2',
      tableType: 'co2',
      breatheUpSeconds: 60,
      holdSeconds: 90,
      restSeconds: 120,
      rounds: buildCo2Rounds(90, 120, 15, 8),
      week: 1,
      sessionIndex: 1,
      planKey: 'beginner:1:',
      language: 'en',
      trainingHaptic: true,
      trainingSound: true,
      loggedCount: 4,
      syncedAt: [1700000000000],
      tables: {
        breatheUpSeconds: 60,
        co2: {
          name: 'CO2',
          tableType: 'co2',
          holdSeconds: 90,
          restSeconds: 120,
          rounds: buildCo2Rounds(90, 120, 15, 8),
        },
        o2: {
          name: 'O2',
          tableType: 'o2',
          holdSeconds: 60,
          restSeconds: 120,
          rounds: [{ hold: 60, rest: 120 }],
        },
      },
    })
    assert.equal(payload.type, 'nextSession')
    assert.equal(payload.rounds.length, 8)
    assert.equal(payload.week, 1)
    assert.deepEqual(payload.syncedAt, [1700000000])
    assert.equal('schedule' in payload, false)
    assert.equal(payload.planKey, 'beginner:1:')
  })

  it('hashes a plan key longer than 96 characters', () => {
    const custom = JSON.stringify({ weeks: 12, sessions: Array.from({ length: 48 }, () => 'co2') })
    const planKey = `custom:1:${custom}:freediver`
    assert.ok(planKey.length > 96)
    const wire = wirePlanKey(planKey)
    assert.equal(wire, wirePlanKey(planKey))
    assert.notEqual(wire, planKey)
    assert.equal(wire.startsWith('plan:'), true)
    assert.ok(wire.length < 24)
    assert.equal(wirePlanKey('beginner:1:'), 'beginner:1:')
    const payload = slimNextSession({ type: 'nextSession', planKey, locked: true })
    assert.equal(payload.planKey, wire)
  })

  it('builds a standalone phoneTraining message', () => {
    const live = phoneTrainingMessage({
      running: true,
      paused: false,
      name: 'CO2',
      phase: 'hold',
      startedAt: 10,
    })
    assert.equal(live.type, 'phoneTraining')
    assert.equal(live.name, 'CO2')
    assert.equal(live.running, true)
    const idle = phoneTrainingMessage(undefined)
    assert.equal(idle.type, 'phoneTraining')
    assert.equal(idle.running, false)
    assert.equal(idle.name, undefined)
  })

  it('keeps lock and complete snapshots small', () => {
    const locked = slimNextSession({ type: 'nextSession', locked: true, language: 'fr' })
    assert.equal(locked.locked, true)
    assert.equal(locked.rounds, undefined)
    const complete = slimNextSession({ type: 'nextSession', complete: true })
    assert.equal(complete.complete, true)
  })
})

describe('watch completion', () => {
  it('normalizes a Garmin sessionComplete payload for the iOS SQLite path', () => {
    const parsed = parseWatchMessage({
      type: 'sessionComplete',
      tableType: 'co2',
      holdSeconds: 90,
      restSeconds: 120,
      roundsCompleted: 8,
      roundsPlanned: 8,
      startedAt: 1700000000,
      completedAt: 1700001000,
      source: 'watch',
      watchDetail: 'garmin',
      heartRates: [{ bpm: 68, at: 1700000500 }],
    })
    assert.ok(parsed)
    assert.equal(parsed.type, 'sessionComplete')
    assert.equal(parsed.watchDetail, 'garmin')
    assert.equal(parsed.startedAt, 1700000000000)
    assert.equal(parsed.completedAt, 1700001000000)
    assert.equal(parsed.heartRates[0].at, 1700000500000)
    assert.equal(parsed.holdSeconds, 90)
  })

  it('rejects a completion without a table type', () => {
    assert.equal(parseWatchMessage({ type: 'sessionComplete', holdSeconds: 90 }), null)
  })

  it('builds an ack the watch can match on completedAt seconds', () => {
    const ack = buildAck(1700001000000, [1700001000000, 1700000000000])
    assert.equal(ack.type, 'ack')
    assert.equal(ack.saved, true)
    assert.equal(ack.completedAt, 1700001000)
    assert.deepEqual(ack.syncedAt, [1700001000, 1700000000])
  })
})

describe('live watch messages', () => {
  it('parses a repeated watchReady updatedAt as the same ask', () => {
    const ready = parseWatchMessage({ type: 'watchReady', updatedAt: 1700000000 })
    const repeat = parseWatchMessage({ type: 'watchReady', updatedAt: 1700000000 })
    assert.equal(ready.type, 'watchReady')
    assert.equal(repeat.type, 'watchReady')
    assert.equal(ready.updatedAt, 1700000000000)
    assert.equal(repeat.updatedAt, ready.updatedAt)
  })

  it('parses heartRate and watchTraining', () => {
    const hr = parseWatchMessage({ type: 'heartRate', bpm: 72, at: 1700000000 })
    assert.equal(hr.bpm, 72)
    assert.equal(hr.at, 1700000000000)
    const training = parseWatchMessage({
      type: 'watchTraining',
      running: true,
      paused: false,
      name: 'CO2',
      phase: 'Hold',
      updatedAt: 1700000000,
      pendingCount: 1,
      startedAt: 1699999900,
    })
    assert.equal(training.running, true)
    assert.equal(training.updatedAt, 1700000000000)
  })
})
