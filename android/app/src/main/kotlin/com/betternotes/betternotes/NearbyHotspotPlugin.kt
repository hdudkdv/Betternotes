package com.betternotes.betternotes

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NearbyHotspotPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var boundNetwork: Network? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "notis/nearby_hotspot")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopAll()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startHost" -> startHost(result)
            "connect" -> {
                val ssid = call.argument<String>("ssid").orEmpty()
                val password = call.argument<String>("password").orEmpty()
                if (ssid.isEmpty() || password.isEmpty()) {
                    result.error("args", "ssid and password required", null)
                } else {
                    connect(ssid, password, result)
                }
            }
            "stop" -> {
                stopAll()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun wifiManager(): WifiManager =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

    private fun connectivityManager(): ConnectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private fun startHost(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("unsupported", "Local-only hotspot needs Android 8+", null)
            return
        }
        stopAll()
        try {
            var replied = false
            fun reply(block: () -> Unit) {
                if (replied) return
                replied = true
                Handler(Looper.getMainLooper()).post { block() }
            }
            wifiManager().startLocalOnlyHotspot(
                object : WifiManager.LocalOnlyHotspotCallback() {
                    override fun onStarted(res: WifiManager.LocalOnlyHotspotReservation) {
                        reservation = res
                        val creds = credentials(res)
                        reply {
                            result.success(
                                hashMapOf(
                                    "ssid" to creds.first,
                                    "password" to creds.second,
                                ),
                            )
                        }
                    }

                    override fun onFailed(reason: Int) {
                        reply {
                            result.error("failed", "hotspot failed: $reason", null)
                        }
                    }
                },
                Handler(Looper.getMainLooper()),
            )
        } catch (e: SecurityException) {
            result.error("permission", e.message, null)
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }

    @Suppress("DEPRECATION")
    private fun credentials(res: WifiManager.LocalOnlyHotspotReservation): Pair<String, String> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val sap = res.softApConfiguration
            val ssid = if (Build.VERSION.SDK_INT >= 33) {
                sap.wifiSsid?.toString()?.trim('"') ?: sap.ssid?.trim('"').orEmpty()
            } else {
                sap.ssid?.trim('"').orEmpty()
            }
            return ssid to (sap.passphrase ?: "")
        }
        val config = res.wifiConfiguration
        return (config?.SSID ?: "").trim('"') to (config?.preSharedKey ?: "")
    }

    private fun connect(ssid: String, password: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported", "Wi-Fi join needs Android 10+", null)
            return
        }
        unbindNetwork()
        val specifier = WifiNetworkSpecifier.Builder()
            .setSsid(ssid)
            .setWpa2Passphrase(password)
            .build()
        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(specifier)
            .build()
        val cm = connectivityManager()
        val callback = object : ConnectivityManager.NetworkCallback() {
            private var replied = false
            private fun reply(value: Boolean) {
                if (replied) return
                replied = true
                Handler(Looper.getMainLooper()).post { result.success(value) }
            }

            override fun onAvailable(network: Network) {
                boundNetwork = network
                cm.bindProcessToNetwork(network)
                reply(true)
            }

            override fun onUnavailable() {
                reply(false)
            }
        }
        networkCallback = callback
        try {
            cm.requestNetwork(request, callback, 15_000)
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }

    private fun unbindNetwork() {
        val cm = connectivityManager()
        try {
            cm.bindProcessToNetwork(null)
        } catch (_: Exception) {
        }
        networkCallback?.let {
            try {
                cm.unregisterNetworkCallback(it)
            } catch (_: Exception) {
            }
        }
        networkCallback = null
        boundNetwork = null
    }

    private fun stopAll() {
        unbindNetwork()
        try {
            reservation?.close()
        } catch (_: Exception) {
        }
        reservation = null
    }
}
