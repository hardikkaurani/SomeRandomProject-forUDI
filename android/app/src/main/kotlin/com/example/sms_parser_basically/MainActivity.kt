package com.example.sms_parser_basically

import android.Manifest
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null

    companion object {
        private const val SMS_PERMISSION_REQUEST_CODE = 1107
        private const val DEVICE_SETTINGS_CHANNEL = "sms_parser_basically/device_settings"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_SETTINGS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isMiuiDevice" -> result.success(isMiuiDevice())
                "openBackgroundSettings" -> result.success(openBackgroundSettings())
                "requestSmsPermissions" -> requestSmsPermissions(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun requestSmsPermissions(result: MethodChannel.Result) {
        val permissions = arrayOf(
            Manifest.permission.READ_SMS,
            Manifest.permission.RECEIVE_SMS
        )

        val missingPermissions = permissions.filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isEmpty()) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error(
                "PERMISSION_IN_PROGRESS",
                "An SMS permission request is already in progress.",
                null
            )
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            missingPermissions.toTypedArray(),
            SMS_PERMISSION_REQUEST_CODE
        )
    }

    private fun isMiuiDevice(): Boolean {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        return manufacturer.contains("xiaomi") ||
            brand.contains("xiaomi") ||
            brand.contains("redmi") ||
            brand.contains("poco")
    }

    private fun openBackgroundSettings(): Boolean {
        val intents = mutableListOf<Intent>()

        if (isMiuiDevice()) {
            intents += Intent().apply {
                component = ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity"
                )
            }
            intents += Intent("miui.intent.action.OP_AUTO_START").apply {
                setPackage("com.miui.securitycenter")
            }
        }

        intents += Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        intents += Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
        }

        intents.forEach { intent ->
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        }

        return false
    }
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != SMS_PERMISSION_REQUEST_CODE) {
            return
        }

        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }

        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }
}
