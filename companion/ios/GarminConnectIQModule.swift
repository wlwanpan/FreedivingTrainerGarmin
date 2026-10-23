import ExpoModulesCore
import Foundation
import ConnectIQ

private let watchAppUUID = UUID(uuidString: "A851FE4E-15FF-43A5-BA7B-6643C2B06A09")!
private let urlScheme = "freedivingtrainer"
private let restorationId = "freedivingtrainer.garmin.connectiq"
private let lastNextSessionKey = "garmin.lastNextSession"

public class GarminConnectIQModule: Module {
  private let coordinator = GarminCoordinator()

  public func definition() -> ModuleDefinition {
    Name("GarminConnectIQ")

    Events("onMessage", "onDeviceStatus", "onReady")

    Function("watchAppUUID") {
      return watchAppUUID.uuidString.lowercased()
    }

    AsyncFunction("initialize") { (promise: Promise) in
      self.coordinator.initialize { event, body in
        self.sendEvent(event, body)
      }
      promise.resolve(nil)
    }

    AsyncFunction("showDeviceSelection") { (promise: Promise) in
      ConnectIQ.sharedInstance().showConnectIQDeviceSelection()
      promise.resolve(nil)
    }

    AsyncFunction("handleOpenURL") { (urlString: String, promise: Promise) in
      guard let url = URL(string: urlString) else {
        promise.reject("ERR_URL", "Invalid URL")
        return
      }
      let devices = self.coordinator.handleOpenURL(url)
      promise.resolve(devices)
    }

    AsyncFunction("sendNextSession") { (payload: [String: Any], promise: Promise) in
      self.coordinator.send(payload) { result in
        promise.resolve(result)
      }
    }

    AsyncFunction("sendAck") { (payload: [String: Any], promise: Promise) in
      self.coordinator.send(payload) { result in
        promise.resolve(result)
      }
    }

    AsyncFunction("getStatus") { (promise: Promise) in
      promise.resolve(self.coordinator.status())
    }
  }
}

private final class GarminCoordinator: NSObject, IQDeviceEventDelegate, IQAppMessageDelegate {
  private var devices: [UUID: IQDevice] = [:]
  private var apps: [UUID: IQApp] = [:]
  private var emit: ((String, [String: Any]) -> Void)?
  private var ready = false
  private var lastNextSession: [String: Any]?

  func initialize(emit: @escaping (String, [String: Any]) -> Void) {
    self.emit = emit
    lastNextSession = loadLastNextSession()
    ConnectIQ.sharedInstance().initialize(
      withUrlScheme: urlScheme,
      uiOverrideDelegate: nil,
      stateRestorationIdentifier: restorationId
    )
    ready = true
    emit("onReady", ["ok": true])
  }

  func handleOpenURL(_ url: URL) -> [[String: Any]] {
    guard let parsed = ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url) as? [IQDevice] else {
      return []
    }
    devices.removeAll()
    apps.removeAll()
    ConnectIQ.sharedInstance().unregisterForAllDeviceEvents(self)
    ConnectIQ.sharedInstance().unregisterForAllAppMessages(self)
    var result: [[String: Any]] = []
    for device in parsed {
      devices[device.uuid] = device
      ConnectIQ.sharedInstance().registerForDeviceEvents(device, delegate: self)
      let app = IQApp(uuid: watchAppUUID, storeUuid: watchAppUUID, device: device)
      apps[device.uuid] = app
      ConnectIQ.sharedInstance().registerForAppMessages(app, delegate: self)
      result.append(devicePayload(device))
    }
    pushLastNextSession()
    return result
  }

  func send(_ payload: [String: Any], completion: @escaping (String) -> Void) {
    if payload["type"] as? String == "nextSession" {
      cacheNextSession(payload)
    }
    let connected = apps.values.filter { app in
      ConnectIQ.sharedInstance().getDeviceStatus(app.device) == .connected
    }
    if connected.isEmpty {
      completion("notConnected")
      return
    }
    var remaining = connected.count
    var last = "unknown"
    for app in connected {
      ConnectIQ.sharedInstance().sendMessage(
        payload,
        to: app,
        progress: { _, _ in },
        completion: { result in
          last = NSStringFromSendMessageResult(result)
          remaining -= 1
          if remaining == 0 {
            completion(last)
          }
        }
      )
    }
  }

  func status() -> [String: Any] {
    let list = devices.values.map { devicePayload($0) }
    let connected = list.contains { ($0["status"] as? String) == "connected" }
    return [
      "initialized": ready,
      "connected": connected,
      "appInstalled": connected,
      "devices": list,
    ]
  }

  func deviceStatusChanged(_ device: IQDevice, status: IQDeviceStatus) {
    emit?("onDeviceStatus", devicePayload(device))
    if status == .connected {
      pushLastNextSession()
    }
  }

  func deviceCharacteristicsDiscovered(_ device: IQDevice) {
    emit?("onDeviceStatus", devicePayload(device))
    if ConnectIQ.sharedInstance().getDeviceStatus(device) == .connected {
      pushLastNextSession()
    }
  }

  func receivedMessage(_ message: Any, from app: IQApp) {
    emit?("onMessage", ["message": message, "device": devicePayload(app.device)])
    if messageType(message) == "watchReady" {
      pushLastNextSession()
    }
  }

  private func cacheNextSession(_ payload: [String: Any]) {
    lastNextSession = payload
    if PropertyListSerialization.propertyList(payload, isValidFor: .xml) {
      UserDefaults.standard.set(payload, forKey: lastNextSessionKey)
    }
  }

  private func loadLastNextSession() -> [String: Any]? {
    UserDefaults.standard.dictionary(forKey: lastNextSessionKey)
  }

  private func pushLastNextSession() {
    guard let payload = lastNextSession else { return }
    send(payload) { _ in }
  }

  private func messageType(_ message: Any) -> String? {
    if let dict = message as? [String: Any] {
      return dict["type"] as? String
    }
    if let dict = message as? NSDictionary {
      return dict["type"] as? String
    }
    return nil
  }

  private func devicePayload(_ device: IQDevice) -> [String: Any] {
    let status = ConnectIQ.sharedInstance().getDeviceStatus(device)
    return [
      "uuid": device.uuid.uuidString,
      "modelName": device.modelName ?? "",
      "friendlyName": device.friendlyName ?? "",
      "partNumber": device.partNumber ?? "",
      "status": statusName(status),
    ]
  }

  private func statusName(_ status: IQDeviceStatus) -> String {
    switch status {
    case .invalidDevice: return "invalid"
    case .bluetoothNotReady: return "bluetoothNotReady"
    case .notFound: return "notFound"
    case .notConnected: return "notConnected"
    case .connected: return "connected"
    @unknown default: return "unknown"
    }
  }
}
