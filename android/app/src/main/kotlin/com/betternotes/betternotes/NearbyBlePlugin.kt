package com.betternotes.betternotes

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.util.UUID

@SuppressLint("MissingPermission")
class NearbyBlePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "NearbyBle"
        val SERVICE_UUID: UUID = UUID.fromString("6e6f7469-7300-4000-8000-00000000b1e5")
        val CHAR_UUID: UUID = UUID.fromString("6e6f7469-7300-4000-8000-00000000c0de")
    }

    private lateinit var channel: MethodChannel
    private lateinit var events: EventChannel
    private lateinit var context: Context
    private val main = Handler(Looper.getMainLooper())

    private var sink: EventChannel.EventSink? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var scanner: BluetoothLeScanner? = null
    private var gattServer: BluetoothGattServer? = null
    private var payloadBytes: ByteArray = ByteArray(0)
    private var advertising = false
    private var scanning = false
    private var pendingRead: MethodChannel.Result? = null
    private var readGatt: BluetoothGatt? = null

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartFailure(errorCode: Int) {
            Log.w(TAG, "advertise failed: $errorCode")
        }
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            emitBeacon(result)
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>) {
            for (result in results) emitBeacon(result)
        }
    }

    private fun bluetoothManager(): BluetoothManager? =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager

    private fun adapter(): BluetoothAdapter? = bluetoothManager()?.adapter

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "notis/nearby_ble")
        channel.setMethodCallHandler(this)
        events = EventChannel(binding.binaryMessenger, "notis/nearby_ble_events")
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
        stopAll()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startAdvertise" -> {
                val name = call.argument<String>("name").orEmpty()
                val payload = call.argument<String>("payload").orEmpty()
                val shareId = call.argument<String>("shareId").orEmpty()
                startAdvertise(name, payload, shareId, result)
            }
            "stopAdvertise" -> {
                stopAdvertise()
                result.success(null)
            }
            "startScan" -> {
                startScan(result)
            }
            "stopScan" -> {
                stopScan()
                result.success(null)
            }
            "readPayload" -> {
                val id = call.argument<String>("id").orEmpty()
                readPayload(id, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun startAdvertise(name: String, payload: String, shareId: String, result: MethodChannel.Result) {
        val adapter = adapter()
        if (adapter == null || !adapter.isEnabled) {
            result.error("bt", "Bluetooth is off", null)
            return
        }
        payloadBytes = payload.toByteArray(StandardCharsets.UTF_8)
        stopAdvertise()
        val manager = bluetoothManager()
        if (manager != null) {
            gattServer = manager.openGattServer(context, object : BluetoothGattServerCallback() {
                override fun onCharacteristicReadRequest(
                    device: BluetoothDevice,
                    requestId: Int,
                    offset: Int,
                    characteristic: BluetoothGattCharacteristic
                ) {
                    val data = payloadBytes
                    val slice = if (offset >= data.size) ByteArray(0) else data.copyOfRange(offset, data.size)
                    gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, slice)
                }
            })
            val service = BluetoothGattService(SERVICE_UUID, BluetoothGattService.SERVICE_TYPE_PRIMARY)
            val characteristic = BluetoothGattCharacteristic(
                CHAR_UUID,
                BluetoothGattCharacteristic.PROPERTY_READ,
                BluetoothGattCharacteristic.PERMISSION_READ
            )
            characteristic.value = payloadBytes
            service.addCharacteristic(characteristic)
            gattServer?.addService(service)
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .build()
        val shareBytes = shareId.replace("-", "").take(16).toByteArray(StandardCharsets.US_ASCII)
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .addServiceData(ParcelUuid(SERVICE_UUID), shareBytes)
            .build()
        val scanResponse = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addServiceData(
                ParcelUuid(CHAR_UUID),
                name.toByteArray(StandardCharsets.UTF_8).copyOf(minOf(name.toByteArray().size, 20))
            )
            .build()
        advertiser = adapter.bluetoothLeAdvertiser
        try {
            advertiser?.startAdvertising(settings, data, scanResponse, advertiseCallback)
            advertising = true
            result.success(null)
        } catch (error: Exception) {
            result.error("advertise", error.message, null)
        }
    }

    private fun stopAdvertise() {
        try {
            if (advertising) advertiser?.stopAdvertising(advertiseCallback)
        } catch (_: Exception) {
        }
        advertising = false
        try {
            gattServer?.close()
        } catch (_: Exception) {
        }
        gattServer = null
    }

    private fun startScan(result: MethodChannel.Result) {
        val adapter = adapter()
        if (adapter == null || !adapter.isEnabled) {
            result.error("bt", "Bluetooth is off", null)
            return
        }
        stopScan()
        scanner = adapter.bluetoothLeScanner
        val filter = ScanFilter.Builder().setServiceUuid(ParcelUuid(SERVICE_UUID)).build()
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()
        try {
            scanner?.startScan(listOf(filter), settings, scanCallback)
            scanning = true
            result.success(null)
        } catch (error: Exception) {
            result.error("scan", error.message, null)
        }
    }

    private fun stopScan() {
        try {
            if (scanning) scanner?.stopScan(scanCallback)
        } catch (_: Exception) {
        }
        scanning = false
    }

    private fun emitBeacon(result: ScanResult) {
        val device = result.device ?: return
        val record = result.scanRecord
        val shareBytes = record?.getServiceData(ParcelUuid(SERVICE_UUID))
        val nameBytes = record?.getServiceData(ParcelUuid(CHAR_UUID))
        val name = when {
            nameBytes != null && nameBytes.isNotEmpty -> String(nameBytes, StandardCharsets.UTF_8).trim()
            !record?.deviceName.isNullOrBlank() -> record!!.deviceName!!
            !device.name.isNullOrBlank() -> device.name
            else -> "Notis"
        }
        val shareId = shareBytes?.let { String(it, StandardCharsets.US_ASCII).trim() }
        val payload = hashMapOf<String, Any?>(
            "event" to "beacon",
            "id" to device.address,
            "name" to name,
            "rssi" to result.rssi,
            "shareId" to shareId,
        )
        main.post { sink?.success(payload) }
    }

    private fun readPayload(id: String, result: MethodChannel.Result) {
        val adapter = adapter()
        if (adapter == null || id.isEmpty) {
            result.error("args", "missing device", null)
            return
        }
        pendingRead?.error("cancelled", "superseded", null)
        pendingRead = result
        try {
            readGatt?.close()
        } catch (_: Exception) {
        }
        val device = try {
            adapter.getRemoteDevice(id)
        } catch (_: Exception) {
            pendingRead = null
            result.error("device", "unknown", null)
            return
        }
        val callback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    gatt.discoverServices()
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    finishRead(null, "disconnected")
                    try {
                        gatt.close()
                    } catch (_: Exception) {
                    }
                }
            }

            override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
                val characteristic = gatt.getService(SERVICE_UUID)?.getCharacteristic(CHAR_UUID)
                if (characteristic == null) {
                    finishRead(null, "no_service")
                    gatt.disconnect()
                    return
                }
                gatt.readCharacteristic(characteristic)
            }

            @Deprecated("Deprecated in Java")
            override fun onCharacteristicRead(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                status: Int
            ) {
                handleRead(gatt, characteristic.value, status)
            }

            override fun onCharacteristicRead(
                gatt: BluetoothGatt,
                characteristic: BluetoothGattCharacteristic,
                value: ByteArray,
                status: Int
            ) {
                handleRead(gatt, value, status)
            }

            private fun handleRead(gatt: BluetoothGatt, value: ByteArray?, status: Int) {
                val text = if (status == BluetoothGatt.GATT_SUCCESS && value != null) {
                    String(value, StandardCharsets.UTF_8)
                } else {
                    null
                }
                finishRead(text, if (text == null) "read_failed" else null)
                gatt.disconnect()
            }
        }
        readGatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            device.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
        } else {
            device.connectGatt(context, false, callback)
        }
        main.postDelayed({
            if (pendingRead === result) {
                finishRead(null, "timeout")
                try {
                    readGatt?.disconnect()
                    readGatt?.close()
                } catch (_: Exception) {
                }
            }
        }, 8000)
    }

    private fun finishRead(value: String?, error: String?) {
        val pending = pendingRead ?: return
        pendingRead = null
        main.post {
            if (value != null) {
                pending.success(value)
            } else {
                pending.error("read", error ?: "failed", null)
            }
        }
    }

    private fun stopAll() {
        stopScan()
        stopAdvertise()
        try {
            readGatt?.close()
        } catch (_: Exception) {
        }
        readGatt = null
    }
}
