package com.example.hotpadapp_v4

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL_SYSTEM_INFO = "system_info"
    private val CHANNEL_INTERNAL_STORAGE = "internal_storage"
    private val CHANNEL_USB_STORAGE = "usb_storage"

    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // SerialCommunicationPlugin 초기화
        flutterEngine.plugins.add(SerialCommunicationPlugin())

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_USB_STORAGE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SYSTEM_INFO).setMethodCallHandler { call, result ->
            if (call.method == "getOSVersion") {
                result.success(getOSVersion())
            }
            else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_INTERNAL_STORAGE).setMethodCallHandler { call, result ->
            if (call.method == "getIntStorageInfo") {
                val intStoragePath = Environment.getExternalStorageDirectory().absolutePath // primary 경로
                val intStorage = File(intStoragePath)
//                val intStorage = File("/storage/emulated/0/")

                if (intStorage.exists() && intStorage.isDirectory) {
                    val statFs = StatFs(intStorage.path)
                    val totalBytes = statFs.totalBytes
                    val usedBytes = totalBytes - statFs.availableBytes
                    val freeBytes = statFs.availableBytes

                    result.success(listOf(totalBytes, usedBytes, freeBytes))
                }
                else {
                    result.error("UNAVAILABLE", "Internal storage not available", null)
                }
            }
            else {
                result.notImplemented()
            }
        }

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getUSBStorageInfo" -> {
                    val usbStoragePath = getUSBStoragePath()
                    if (usbStoragePath != null) {
                        val usbStorage = File(usbStoragePath)
                        if (usbStorage.exists() && usbStorage.isDirectory) {
                            val statFs = StatFs(usbStorage.path)
                            val totalBytes = statFs.totalBytes
                            val usedBytes = totalBytes - statFs.availableBytes
                            val freeBytes = statFs.availableBytes

                            result.success(listOf(totalBytes, usedBytes, freeBytes, usbStoragePath))
                        }
                        else {
                            result.error("UNAVAILABLE", "USB storage not available", null)
                        }
                    }
                    else {
                        result.error("UNAVAILABLE", "USB storage not found", null)
                    }
                }
                "ejectUSB" -> {
                    val success = ejectUSBStorage()
                    if (success) {
                        result.success("USB Eject Request Sent")
                    }
                    else {
                        result.error("UNAVAILABLE", "Failed to eject USB storage", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // USB mount 이벤트를 감지하기 위한 BroadcastReceiver 등록
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_MEDIA_MOUNTED)
            addDataScheme("file")
        }
        registerReceiver(usbReceiver, filter)
    }

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == Intent.ACTION_MEDIA_MOUNTED) {
                // USB가 마운트되었을 때 Flutter로 알림
                methodChannel.invokeMethod("onUSBMounted", null)
            }
        }
    }

    private fun getOSVersion(): String {
        return "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
    }

    private fun getUSBStoragePath(): String? {
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val storageVolumes: List<StorageVolume> = storageManager.storageVolumes

        for (storageVolume in storageVolumes) {
            if (storageVolume.isRemovable && storageVolume.state == Environment.MEDIA_MOUNTED) {
                return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    storageVolume.directory?.path
                }
                else {
                    getVolumePath(storageVolume)
                }
            }
        }
        return null
    }

    @Suppress("DEPRECATION")
    private fun getVolumePath(storageVolume: StorageVolume): String? {
        try {
            val getPathMethod = StorageVolume::class.java.getDeclaredMethod("getPath")
            return getPathMethod.invoke(storageVolume) as String
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    fun ejectUSBStorage(): Boolean {
        val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val storageVolumes: List<StorageVolume> = storageManager.storageVolumes

        for (storageVolume in storageVolumes) {
//            if (storageVolume.isRemovable && storageVolume.state == Environment.MEDIA_MOUNTED) {
            if (storageVolume.isRemovable && storageVolume.state == "mounted") {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        val intent = storageVolume.createAccessIntent(null)
                        if (intent != null) {
                            startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            return true
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
        return false
    }
}