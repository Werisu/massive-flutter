package space.manus.massive.arms.t20260324141650

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            KEEP_ALIVE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    KeepAliveService.start(this)
                    result.success(true)
                }
                "stop" -> {
                    KeepAliveService.stop(this)
                    result.success(true)
                }
                "isRunning" -> result.success(KeepAliveService.isRunning)
                "isIgnoringBatteryOptimizations" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "requestIgnoreBatteryOptimizations" -> {
                    result.success(requestIgnoreBatteryOptimizations())
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_WAKE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEnabled" -> {
                    setKeepScreenOn(call.argument<Boolean>("enabled") == true)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            REST_OVERLAY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(RestTimerOverlay.hasPermission(this))
                "requestPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "show" -> {
                    val endsAt = longArg(call.argument("endsAtMillis"))
                    if (endsAt == null) {
                        result.error("bad_args", "endsAtMillis obrigatório", null)
                    } else {
                        RestTimerOverlay.show(this, endsAt)
                        result.success(true)
                    }
                }
                "hide" -> {
                    RestTimerOverlay.hide()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimizations(): Boolean {
        if (isIgnoringBatteryOptimizations()) return true
        return try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
            true
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Exception) {
                // Sem tela de bateria disponível.
            }
            false
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        if (RestTimerOverlay.hasPermission(this)) return
        try {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName"),
                ),
            )
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
            } catch (_: Exception) {
                // Sem tela de permissão disponível.
            }
        }
    }

    private fun setKeepScreenOn(enabled: Boolean) {
        runOnUiThread {
            if (enabled) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

    private fun longArg(value: Any?): Long? = when (value) {
        is Long -> value
        is Int -> value.toLong()
        is Number -> value.toLong()
        else -> null
    }

    companion object {
        private const val KEEP_ALIVE_CHANNEL = "space.manus.massive.arms/keep_alive"
        private const val SCREEN_WAKE_CHANNEL = "space.manus.massive.arms/screen_wake"
        private const val REST_OVERLAY_CHANNEL = "space.manus.massive.arms/rest_overlay"
    }
}
