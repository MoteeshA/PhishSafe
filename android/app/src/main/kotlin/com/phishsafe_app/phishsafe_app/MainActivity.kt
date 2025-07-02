package com.phishsafe_app.phishsafe_app

import android.hardware.display.DisplayManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "phishsafe/screen_sharing"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "isScreenSharing") {
                    val isSharing = isScreenBeingShared()
                    result.success(isSharing)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun isScreenBeingShared(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val displayManager = getSystemService(DISPLAY_SERVICE) as DisplayManager
            val displays = displayManager.displays
            return displays.any { it.displayId != 0 } // If any display other than default is active
        }
        return false
    }
}
