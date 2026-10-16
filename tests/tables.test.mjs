import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { buildCo2Rounds, buildO2Rounds, makePhases, remainingAt } from '../companion/src/protocol.ts'

describe('table builders', () => {
  it('matches the iOS default CO2 table', () => {
    const rounds = buildCo2Rounds(90, 120, 15, 8)
    assert.equal(rounds.length, 8)
    assert.deepEqual(rounds[0], { hold: 90, rest: 120 })
    assert.deepEqual(rounds[7], { hold: 90, rest: 15 })
  })

  it('matches the iOS default O2 table', () => {
    const rounds = buildO2Rounds(60, 15, 120, 8)
    assert.equal(rounds.length, 8)
    assert.deepEqual(rounds[0], { hold: 60, rest: 120 })
    assert.deepEqual(rounds[7], { hold: 165, rest: 120 })
  })

  it('builds breathe, hold, rest phases', () => {
    const phases = makePhases(60, [{ hold: 90, rest: 120 }, { hold: 90, rest: 105 }])
    assert.equal(phases.length, 5)
    assert.equal(phases[0].title, 'Breathe')
    assert.equal(phases[1].title, 'Hold')
    assert.equal(phases[2].title, 'Rest')
    assert.equal(phases[4].round, 2)
  })
})

describe('timer remaining', () => {
  it('stays on breathe-up for the first minute', () => {
    const phases = makePhases(60, [{ hold: 90, rest: 120 }])
    assert.deepEqual(remainingAt(0, phases), { title: 'Breathe', remaining: 60 })
    assert.deepEqual(remainingAt(59, phases), { title: 'Breathe', remaining: 1 })
  })

  it('moves into hold then rest then finished', () => {
    const phases = makePhases(60, [{ hold: 90, rest: 120 }])
    assert.deepEqual(remainingAt(60, phases), { title: 'Hold', remaining: 90 })
    assert.deepEqual(remainingAt(150, phases), { title: 'Rest', remaining: 120 })
    assert.equal(remainingAt(270, phases), 'finished')
  })
})
