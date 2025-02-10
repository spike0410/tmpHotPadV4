package com.example.hotpadapp_v4

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import android.content.Context
import android.os.Handler
import android.os.Looper
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

class SerialCommunicationPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context
    private var ttyFileOutputStream: FileOutputStream? = null
    private var ttyFileInputStream: FileInputStream? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isReading = false

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "serial_communication")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getSerialPorts" -> {
                val serialPorts = getSerialPorts()
                result.success(serialPorts)
            }
            "openSerialPort" -> {
                val portName = call.argument<String>("portName")
                val baudRate = call.argument<Int>("baudRate") ?: 9600
                val success = openSerialPort(portName, baudRate)
                result.success(success)
                if (success) {
                    startReading()
                }
            }
            "sendData" -> {
                val data = call.argument<String>("data")
                val success = sendData(data)
                result.success(success)
            }
            else -> result.notImplemented()
        }
    }

    private fun getSerialPorts(): List<String> {
        val serialPorts = mutableListOf<String>()
        val devDirectory = File("/dev/")
        if (devDirectory.exists() && devDirectory.isDirectory) {
            val files = devDirectory.listFiles { file -> file.name.startsWith("ttyS") || file.name.startsWith("ttyACM")}
            if (files != null) {
                for (file in files) {
                    serialPorts.add(file.absolutePath)
                }
            }
        }
        return serialPorts
    }

    private fun openSerialPort(portName: String?, baudRate: Int): Boolean {
        return try {
            val file = File(portName)
            ttyFileInputStream = FileInputStream(file)
            ttyFileOutputStream = FileOutputStream(file)
            // Configure the tty port (you may need to use stty or similar commands to set baud rate)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun sendData(data: String?): Boolean {
        return try {
            if (ttyFileOutputStream != null && data != null) {
                ttyFileOutputStream!!.write(data.toByteArray())
                ttyFileOutputStream!!.flush()
                true
            } else {
                false
            }
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }

    private fun startReading() {
        isReading = true
        handler.post(readRunnable)
    }

    private fun stopReading() {
        isReading = false
        handler.removeCallbacks(readRunnable)
    }

    private val readRunnable = object : Runnable {
        override fun run() {
            if (isReading) {
                val data = receiveData()
                if (data != null) {
                    channel.invokeMethod("onDataReceived", data)
                }
                handler.postDelayed(this, 100) // Adjust delay as needed
            }
        }
    }

    private fun receiveData(): String? {
        return try {
            if (ttyFileInputStream != null) {
                val buffer = ByteArray(1024)
                val bytesRead = ttyFileInputStream!!.read(buffer)
                if (bytesRead > 0) {
                    String(buffer, 0, bytesRead)
                } else {
                    null
                }
            } else {
                null
            }
        } catch (e: IOException) {
            e.printStackTrace()
            null
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        stopReading()
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {}
    override fun onDetachedFromActivity() {}
    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
}