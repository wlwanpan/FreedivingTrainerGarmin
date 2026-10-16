const { withInfoPlist, withEntitlementsPlist } = require('@expo/config-plugins')

const URL_SCHEME = 'freedivingtrainer'
const BLUETOOTH_MESSAGE =
  'Freediving Trainer talks to your Garmin watch over Bluetooth to sync tables and completed sessions.'

function unique(values) {
  return [...new Set(values.filter(Boolean))]
}

function withGarminConnectIQ(config) {
  config = withInfoPlist(config, (mod) => {
    const info = mod.modResults
    const modes = unique([...(info.UIBackgroundModes || []), 'bluetooth-central'])
    info.UIBackgroundModes = modes

    const schemes = unique([...(info.LSApplicationQueriesSchemes || []), 'gcm-ciq'])
    info.LSApplicationQueriesSchemes = schemes

    info.NSBluetoothAlwaysUsageDescription =
      info.NSBluetoothAlwaysUsageDescription || BLUETOOTH_MESSAGE
    info.NSBluetoothPeripheralUsageDescription =
      info.NSBluetoothPeripheralUsageDescription || BLUETOOTH_MESSAGE

    const types = info.CFBundleURLTypes || []
    const hasScheme = types.some((entry) => (entry.CFBundleURLSchemes || []).includes(URL_SCHEME))
    if (!hasScheme) {
      types.push({
        CFBundleURLName: 'com.wlwanpan.FreedivingTrainer.garmin',
        CFBundleURLSchemes: [URL_SCHEME],
      })
      info.CFBundleURLTypes = types
    }
    if (!info.CFBundleDisplayName) {
      info.CFBundleDisplayName = '${PRODUCT_NAME}'
    }
    return mod
  })

  config = withEntitlementsPlist(config, (mod) => {
    return mod
  })

  return config
}

module.exports = withGarminConnectIQ
