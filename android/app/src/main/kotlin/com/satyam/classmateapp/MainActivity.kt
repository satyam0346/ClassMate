package com.satyam.classmateapp

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val SECURE_CHANNEL = "com.classmate.app/secure_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── FLAG_SECURE method channel ─────────────────────────────
        // This channel is called by Dart SecureScreen.enable() / .disable()
        // to prevent screenshots and screen recording on sensitive screens.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURE_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "enable" -> {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            result.success(null)
                        }
                        "disable" -> {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    // Never let a flag failure crash the app
                    result.error("FLAG_SECURE_ERROR", e.message, null)
                }
            }
    }
}
