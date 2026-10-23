export {
  WATCH_APP_UUID,
  WATCH_APP_UUID_HEX,
  IOS_URL_SCHEME,
  GCM_QUERY_SCHEME,
  BLE_RESTORATION_ID,
  WATCH_DETAIL,
} from './uuid'
export {
  slimNextSession,
  buildAck,
  parseWatchMessage,
  toUnixMs,
  syncedAtSeconds,
  buildCo2Rounds,
  buildO2Rounds,
  makePhases,
  remainingAt,
} from './protocol'
export type {
  AckMessage,
  HeartRateSample,
  NextSessionMessage,
  PhoneTraining,
  Round,
  TableType,
  WatchMessage,
  WatchTable,
} from './protocol'

export type GarminDevice = {
  uuid: string
  modelName: string
  friendlyName: string
  partNumber?: string
  status: 'invalid' | 'bluetoothNotReady' | 'notFound' | 'notConnected' | 'connected'
}

export type GarminStatus = {
  initialized: boolean
  connected: boolean
  appInstalled: boolean
  devices: GarminDevice[]
}

type NativeModule = {
  watchAppUUID(): string
  initialize(): Promise<void>
  showDeviceSelection(): Promise<void>
  handleOpenURL(url: string): Promise<GarminDevice[]>
  sendNextSession(payload: Record<string, unknown>): Promise<string>
  sendAck(payload: Record<string, unknown>): Promise<string>
  getStatus(): Promise<GarminStatus>
  addListener(event: string, listener: (event: Record<string, unknown>) => void): { remove(): void }
}

let native: NativeModule | null = null

try {
  // Loaded only inside the FreedivingTrainer iOS binary after the Expo module is linked.
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  native = require('expo-modules-core').requireNativeModule('GarminConnectIQ') as NativeModule
} catch {
  native = null
}

export function isGarminModuleAvailable(): boolean {
  return native != null
}

export function watchAppUUID(): string {
  return native?.watchAppUUID() ?? 'a851fe4e-15ff-43a5-ba7b-6643c2b06a09'
}

export async function initialize(): Promise<void> {
  if (!native) throw new Error('Garmin Connect IQ native module is not linked')
  await native.initialize()
}

export async function showDeviceSelection(): Promise<void> {
  if (!native) throw new Error('Garmin Connect IQ native module is not linked')
  await native.showDeviceSelection()
}

export async function handleOpenURL(url: string): Promise<GarminDevice[]> {
  if (!native) throw new Error('Garmin Connect IQ native module is not linked')
  return native.handleOpenURL(url)
}

export async function sendNextSession(payload: Record<string, unknown>): Promise<string> {
  if (!native) throw new Error('Garmin Connect IQ native module is not linked')
  return native.sendNextSession(payload)
}

export async function sendAck(payload: Record<string, unknown>): Promise<string> {
  if (!native) throw new Error('Garmin Connect IQ native module is not linked')
  return native.sendAck(payload)
}

export async function getStatus(): Promise<GarminStatus> {
  if (!native) {
    return { initialized: false, connected: false, appInstalled: false, devices: [] }
  }
  return native.getStatus()
}

export function addGarminListener(
  event: 'onMessage' | 'onDeviceStatus' | 'onReady',
  listener: (event: Record<string, unknown>) => void,
): () => void {
  if (!native) return () => {}
  const sub = native.addListener(event, listener)
  return () => sub.remove()
}
