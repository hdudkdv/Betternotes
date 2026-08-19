import CoreBluetooth
import Flutter
import Foundation
import UIKit

/// BLE peripheral + central for Notis nearby share discovery.
final class NearbyBlePlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate
{
  static let serviceUUID = CBUUID(string: "6E6F7469-7300-4000-8000-00000000B1E5")
  static let charUUID = CBUUID(string: "6E6F7469-7300-4000-8000-00000000C0DE")

  private var channel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?
  private var sink: FlutterEventSink?

  private var peripheralManager: CBPeripheralManager?
  private var centralManager: CBCentralManager?
  private var payload = Data()
  private var advertiseName = "Notis"
  private var gattCharacteristic: CBMutableCharacteristic?
  private var scanning = false

  private var known: [UUID: CBPeripheral] = [:]
  private var pendingRead: FlutterResult?
  private var readPeripheral: CBPeripheral?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NearbyBlePlugin()
    instance.channel = FlutterMethodChannel(
      name: "notis/nearby_ble",
      binaryMessenger: registrar.messenger()
    )
    instance.channel?.setMethodCallHandler(instance.handle)
    instance.eventChannel = FlutterEventChannel(
      name: "notis/nearby_ble_events",
      binaryMessenger: registrar.messenger()
    )
    instance.eventChannel?.setStreamHandler(instance)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "startAdvertise":
      advertiseName = (args["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        ?? "Notis"
      if advertiseName.isEmpty { advertiseName = "Notis" }
      let payloadString = args["payload"] as? String ?? "{}"
      payload = payloadString.data(using: .utf8) ?? Data()
      if peripheralManager == nil {
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
      } else {
        startAdvertisingIfReady()
      }
      result(nil)
    case "stopAdvertise":
      peripheralManager?.stopAdvertising()
      result(nil)
    case "startScan":
      if centralManager == nil {
        centralManager = CBCentralManager(delegate: self, queue: .main)
      }
      scanning = true
      startScanningIfReady()
      result(nil)
    case "stopScan":
      scanning = false
      centralManager?.stopScan()
      result(nil)
    case "readPayload":
      let id = args["id"] as? String ?? ""
      readPayload(id: id, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startAdvertisingIfReady() {
    guard let manager = peripheralManager, manager.state == .poweredOn else { return }
    manager.removeAllServices()
    let characteristic = CBMutableCharacteristic(
      type: NearbyBlePlugin.charUUID,
      properties: [.read],
      value: payload,
      permissions: [.readable]
    )
    gattCharacteristic = characteristic
    let service = CBMutableService(type: NearbyBlePlugin.serviceUUID, primary: true)
    service.characteristics = [characteristic]
    manager.add(service)
  }

  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if peripheral.state == .poweredOn {
      startAdvertisingIfReady()
    }
  }

  func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
    guard error == nil else { return }
    let name = String(advertiseName.prefix(11))
    peripheral.startAdvertising([
      CBAdvertisementDataServiceUUIDsKey: [NearbyBlePlugin.serviceUUID],
      CBAdvertisementDataLocalNameKey: name,
    ])
  }

  private func startScanningIfReady() {
    guard scanning, let central = centralManager, central.state == .poweredOn else { return }
    central.scanForPeripherals(
      withServices: [NearbyBlePlugin.serviceUUID],
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
    )
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn {
      startScanningIfReady()
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    known[peripheral.identifier] = peripheral
    let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
    let name = (localName?.isEmpty == false ? localName : peripheral.name) ?? "Notis"
    sink?([
      "event": "beacon",
      "id": peripheral.identifier.uuidString,
      "name": name,
      "rssi": RSSI.intValue,
    ])
  }

  private func readPayload(id: String, result: @escaping FlutterResult) {
    guard let uuid = UUID(uuidString: id), let peripheral = known[uuid],
      let central = centralManager
    else {
      result(
        FlutterError(code: "device", message: "unknown", details: nil)
      )
      return
    }
    pendingRead?(
      FlutterError(code: "cancelled", message: "superseded", details: nil)
    )
    pendingRead = result
    readPeripheral = peripheral
    peripheral.delegate = self
    if peripheral.state == .connected {
      peripheral.discoverServices([NearbyBlePlugin.serviceUUID])
    } else {
      central.connect(peripheral, options: nil)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
      guard let self, self.pendingRead != nil else { return }
      self.finishRead(nil, error: "timeout")
      if let connected = self.readPeripheral {
        self.centralManager?.cancelPeripheralConnection(connected)
      }
    }
  }

  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    if peripheral.identifier == readPeripheral?.identifier {
      peripheral.discoverServices([NearbyBlePlugin.serviceUUID])
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didFailToConnect peripheral: CBPeripheral,
    error: Error?
  ) {
    if peripheral.identifier == readPeripheral?.identifier {
      finishRead(nil, error: error?.localizedDescription ?? "connect_failed")
    }
  }

  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard error == nil else {
      finishRead(nil, error: error?.localizedDescription)
      return
    }
    let service = peripheral.services?.first { $0.uuid == NearbyBlePlugin.serviceUUID }
    guard let service else {
      finishRead(nil, error: "no_service")
      return
    }
    peripheral.discoverCharacteristics([NearbyBlePlugin.charUUID], for: service)
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didDiscoverCharacteristicsFor service: CBService,
    error: Error?
  ) {
    guard error == nil else {
      finishRead(nil, error: error?.localizedDescription)
      return
    }
    let characteristic = service.characteristics?.first { $0.uuid == NearbyBlePlugin.charUUID }
    guard let characteristic else {
      finishRead(nil, error: "no_char")
      return
    }
    peripheral.readValue(for: characteristic)
  }

  func peripheral(
    _ peripheral: CBPeripheral,
    didUpdateValueFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    guard error == nil, let data = characteristic.value,
      let text = String(data: data, encoding: .utf8)
    else {
      finishRead(nil, error: error?.localizedDescription ?? "read_failed")
      return
    }
    finishRead(text, error: nil)
    centralManager?.cancelPeripheralConnection(peripheral)
  }

  private func finishRead(_ value: String?, error: String?) {
    guard let pending = pendingRead else { return }
    pendingRead = nil
    if let value {
      pending(value)
    } else {
      pending(FlutterError(code: "read", message: error ?? "failed", details: nil))
    }
  }
}
