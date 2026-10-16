export const WATCH_DETAIL = 'garmin' as const

export type TableType = 'co2' | 'o2' | 'one-breath' | 'walk'

export type Round = {
  hold: number
  rest: number
}

export type WatchTable = {
  name: string
  tableType: 'co2' | 'o2'
  holdSeconds: number
  restSeconds: number
  rounds: Round[]
}

export type PhoneTraining = {
  running: boolean
  paused?: boolean
  name?: string
  phase?: string
  startedAt?: number
}

export type NextSessionMessage = {
  type: 'nextSession'
  name?: string
  tableType?: TableType
  breatheUpSeconds?: number
  holdSeconds?: number
  restSeconds?: number
  rounds?: Round[]
  week?: number
  sessionIndex?: number
  planKey?: string
  planWeek?: number
  planWeeks?: number
  progress?: number
  planName?: string
  language?: string
  trainingHaptic?: boolean
  trainingSound?: boolean
  phoneTraining?: PhoneTraining
  locked?: boolean
  complete?: boolean
  loggedCount?: number
  sync?: '' | 'plan' | 'erase'
  syncedAt?: number[]
  tables?: {
    breatheUpSeconds: number
    co2: WatchTable
    o2: WatchTable
  }
}

export type AckMessage = {
  type: 'ack'
  saved: boolean
  completedAt: number
  syncedAt?: number[]
}

export type HeartRateSample = {
  bpm: number
  at: number
}

export type WatchMessage =
  | {
      type: 'watchTraining'
      running: boolean
      paused: boolean
      name: string
      phase: string
      updatedAt: number
      pendingCount: number
      startedAt?: number
    }
  | {
      type: 'heartRate'
      bpm: number
      at: number
    }
  | {
      type: 'sessionComplete'
      tableType: TableType
      holdSeconds: number
      restSeconds: number
      roundsCompleted: number
      roundsPlanned: number
      startedAt: number
      completedAt: number
      source: 'watch'
      watchDetail: 'garmin'
      heartRates?: HeartRateSample[]
      week?: number
      sessionIndex?: number
      planKey?: string
    }

const MS_THRESHOLD = 1e11

export function toUnixMs(value: unknown): number | null {
  const parsed = typeof value === 'number' ? value : Number(value)
  if (!Number.isFinite(parsed) || parsed <= 0) return null
  const rounded = Math.round(parsed)
  if (rounded > MS_THRESHOLD) return rounded
  return rounded * 1000
}

export function syncedAtSeconds(values: number[]): number[] {
  return values.map((value) => {
    if (value > MS_THRESHOLD) return Math.round(value / 1000)
    return Math.round(value)
  })
}

export function slimNextSession(input: NextSessionMessage): NextSessionMessage {
  const rounds = (input.rounds ?? []).slice(0, 40).map((round) => ({
    hold: Math.round(round.hold),
    rest: Math.max(0, Math.round(round.rest)),
  }))
  const payload: NextSessionMessage = {
    type: 'nextSession',
    language: input.language,
    trainingHaptic: input.trainingHaptic,
    trainingSound: input.trainingSound,
    phoneTraining: input.phoneTraining ?? { running: false },
    loggedCount: input.loggedCount,
    planKey: input.planKey ?? '',
    sync: input.sync ?? '',
    syncedAt: syncedAtSeconds(input.syncedAt ?? []),
  }
  if (input.tables) {
    payload.tables = {
      breatheUpSeconds: input.tables.breatheUpSeconds,
      co2: slimTable(input.tables.co2),
      o2: slimTable(input.tables.o2),
    }
  }
  if (input.locked) {
    payload.locked = true
    return payload
  }
  if (input.complete) {
    payload.complete = true
    return payload
  }
  if (input.name && input.tableType && rounds.length > 0) {
    payload.name = input.name
    payload.tableType = input.tableType
    payload.breatheUpSeconds = input.breatheUpSeconds ?? 0
    payload.holdSeconds = input.holdSeconds
    payload.restSeconds = input.restSeconds
    payload.rounds = rounds
    if ((input.week ?? 0) > 0) payload.week = input.week
    if ((input.sessionIndex ?? 0) > 0) payload.sessionIndex = input.sessionIndex
    if (input.planWeek) payload.planWeek = input.planWeek
    if (input.planWeeks) payload.planWeeks = input.planWeeks
    if (input.progress != null) payload.progress = input.progress
    if (input.planName) payload.planName = input.planName
  }
  return payload
}

function slimTable(table: WatchTable): WatchTable {
  return {
    name: table.name,
    tableType: table.tableType,
    holdSeconds: table.holdSeconds,
    restSeconds: table.restSeconds,
    rounds: table.rounds.slice(0, 40),
  }
}

export function buildAck(completedAtMs: number, syncedAtMs: number[]): AckMessage {
  return {
    type: 'ack',
    saved: true,
    completedAt: syncedAtSeconds([completedAtMs])[0],
    syncedAt: syncedAtSeconds(syncedAtMs),
  }
}

export function parseWatchMessage(raw: unknown): WatchMessage | null {
  if (raw == null || typeof raw !== 'object') return null
  const record = raw as Record<string, unknown>
  const type = record.type
  if (type === 'heartRate') {
    const bpm = wholeNumber(record.bpm, 30, 230)
    const at = toUnixMs(record.at)
    if (bpm == null || at == null) return null
    return { type: 'heartRate', bpm, at }
  }
  if (type === 'watchTraining') {
    const updatedAt = toUnixMs(record.updatedAt)
    if (updatedAt == null) return null
    const startedAt = toUnixMs(record.startedAt)
    return {
      type: 'watchTraining',
      running: Boolean(record.running),
      paused: Boolean(record.paused),
      name: typeof record.name === 'string' ? record.name : '',
      phase: typeof record.phase === 'string' ? record.phase : '',
      updatedAt,
      pendingCount: wholeNumber(record.pendingCount, 0, 20) ?? 0,
      ...(startedAt != null ? { startedAt } : {}),
    }
  }
  if (type === 'sessionComplete') {
    const tableType = record.tableType
    if (tableType !== 'co2' && tableType !== 'o2' && tableType !== 'one-breath' && tableType !== 'walk') {
      return null
    }
    const holdSeconds = wholeNumber(record.holdSeconds, 1, 3600)
    const restSeconds = wholeNumber(record.restSeconds, 0, 3600)
    const roundsCompleted = wholeNumber(record.roundsCompleted, 1, 40)
    const roundsPlanned = wholeNumber(record.roundsPlanned, 1, 40)
    const completedAt = toUnixMs(record.completedAt)
    const startedAt = toUnixMs(record.startedAt)
    if (
      holdSeconds == null
      || restSeconds == null
      || roundsCompleted == null
      || roundsPlanned == null
      || completedAt == null
      || startedAt == null
    ) return null
    const heartRates = Array.isArray(record.heartRates)
      ? record.heartRates.flatMap((item) => {
          if (item == null || typeof item !== 'object') return []
          const row = item as Record<string, unknown>
          const bpm = wholeNumber(row.bpm, 30, 230)
          const at = toUnixMs(row.at ?? row.recordedAt)
          if (bpm == null || at == null) return []
          return [{ bpm, at }]
        })
      : []
    const payload: WatchMessage = {
      type: 'sessionComplete',
      tableType,
      holdSeconds,
      restSeconds,
      roundsCompleted,
      roundsPlanned,
      startedAt,
      completedAt,
      source: 'watch',
      watchDetail: WATCH_DETAIL,
      heartRates,
    }
    const week = wholeNumber(record.week, 1, 52)
    const sessionIndex = wholeNumber(record.sessionIndex, 1, 40)
    if (week != null) payload.week = week
    if (sessionIndex != null) payload.sessionIndex = sessionIndex
    if (typeof record.planKey === 'string') payload.planKey = record.planKey
    return payload
  }
  return null
}

function wholeNumber(value: unknown, min: number, max: number): number | null {
  const parsed = typeof value === 'number' ? value : Number(value)
  if (!Number.isFinite(parsed)) return null
  const rounded = Math.round(parsed)
  if (rounded < min || rounded > max) return null
  return rounded
}

export function buildCo2Rounds(
  holdSeconds: number,
  restStartSeconds: number,
  restStepSeconds: number,
  rounds: number,
): Round[] {
  return Array.from({ length: rounds }, (_, index) => ({
    hold: holdSeconds,
    rest: Math.max(0, restStartSeconds - index * restStepSeconds),
  }))
}

export function buildO2Rounds(
  holdStartSeconds: number,
  holdStepSeconds: number,
  restSeconds: number,
  rounds: number,
): Round[] {
  return Array.from({ length: rounds }, (_, index) => ({
    hold: holdStartSeconds + index * holdStepSeconds,
    rest: restSeconds,
  }))
}

export function makePhases(
  breatheUpSeconds: number,
  rounds: Round[],
): { title: 'Breathe' | 'Hold' | 'Rest'; seconds: number; round: number | null }[] {
  const phases: { title: 'Breathe' | 'Hold' | 'Rest'; seconds: number; round: number | null }[] = []
  if (breatheUpSeconds > 0) {
    phases.push({ title: 'Breathe', seconds: breatheUpSeconds, round: null })
  }
  rounds.forEach((round, index) => {
    if (round.hold > 0) {
      phases.push({ title: 'Hold', seconds: round.hold, round: index + 1 })
    }
    if (round.rest > 0) {
      phases.push({ title: 'Rest', seconds: round.rest, round: index + 1 })
    }
  })
  return phases
}

export function remainingAt(
  elapsedSeconds: number,
  phases: { title: string; seconds: number }[],
): { title: string; remaining: number } | 'finished' {
  let cursor = elapsedSeconds
  for (const phase of phases) {
    if (cursor < phase.seconds) {
      return { title: phase.title, remaining: phase.seconds - cursor }
    }
    cursor -= phase.seconds
  }
  return 'finished'
}
