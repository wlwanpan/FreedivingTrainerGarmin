import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { buildCo2Rounds, makePhases, remainingAt } from '../companion/src/protocol.ts'

function runUntilFinished(breatheUp, rounds) {
  const phases = makePhases(breatheUp, rounds)
  const total = phases.reduce((sum, phase) => sum + phase.seconds, 0)
  const seen = []
  for (let elapsed = 0; elapsed <= total; elapsed++) {
    const state = remainingAt(elapsed, phases)
    if (state === 'finished') {
      seen.push('finished')
      break
    }
    if (seen[seen.length - 1] !== state.title) {
      seen.push(state.title)
    }
  }
  return { total, seen }
}

describe('full default CO2 session', () => {
  it('runs breathe then eight hold/rest pairs', () => {
    const rounds = buildCo2Rounds(90, 120, 15, 8)
    const { total, seen } = runUntilFinished(60, rounds)
    assert.equal(total, 60 + rounds.reduce((sum, round) => sum + round.hold + round.rest, 0))
    assert.equal(seen[0], 'Breathe')
    assert.equal(seen[1], 'Hold')
    assert.equal(seen[2], 'Rest')
    assert.equal(seen[seen.length - 2], 'Rest')
    assert.equal(seen[seen.length - 1], 'finished')
    assert.equal(seen.filter((title) => title === 'Hold').length, 8)
    assert.equal(seen.filter((title) => title === 'Rest').length, 8)
  })
})
