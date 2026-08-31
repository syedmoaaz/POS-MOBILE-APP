package com.shopos.pos_app

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val channelName = "shopos/printer"
    private val spp: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bonded" -> {
                        try {
                            result.success(bondedDevices())
                        } catch (e: Exception) {
                            result.error("BT", e.message, null)
                        }
                    }
                    "print" -> {
                        val address = call.argument<String>("address")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (address.isNullOrEmpty() || bytes == null) {
                            result.error("ARG", "address/bytes missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            printBytes(address, bytes)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PRINT", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun adapter(): BluetoothAdapter? {
        val mgr = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            mgr.adapter
        } else {
            @Suppress("DEPRECATION")
            BluetoothAdapter.getDefaultAdapter()
        }
    }

    @SuppressLint("MissingPermission")
    private fun bondedDevices(): List<Map<String, String>> {
        val adapter = adapter() ?: return emptyList()
        return adapter.bondedDevices.map { device ->
            mapOf(
                "name" to (device.name ?: "Printer"),
                "address" to device.address,
            )
        }
    }

    @SuppressLint("MissingPermission")
    private fun printBytes(address: String, bytes: ByteArray) {
        val adapter = adapter() ?: throw IllegalStateException("Bluetooth off")
        val device = adapter.getRemoteDevice(address)
        val socket = device.createRfcommSocketToServiceRecord(spp)
        adapter.cancelDiscovery()
        socket.connect()
        socket.outputStream.write(bytes)
        socket.outputStream.flush()
        socket.close()
    }
}
