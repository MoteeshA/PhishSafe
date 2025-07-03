package com.phishsafe_app.phishsafe_app

import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle
import android.view.Display
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "phishsafe/screen_sharing"
    private val TAG = "ScreenSharingMonitor"
    private var lastDetectionTime: Long = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enhanced security flags
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )

        // Additional protection for newer Android versions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isScreenSharing" -> {
                        try {
                            result.success(isScreenBeingShared())
                        } catch (e: Exception) {
                            Log.e(TAG, "Error checking screen sharing", e)
                            result.error("ERROR", "Failed to check screen sharing", null)
                        }
                    }
                    "isScreenRecordingPossible" -> {
                        result.success(isScreenRecordingPossible())
                    }
                    "getSecurityStatus" -> {
                        result.success(getSecurityStatus())
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun isScreenBeingShared(): Boolean {
        // Check with cooldown to prevent too frequent checks
        val now = System.currentTimeMillis()
        if (now - lastDetectionTime < 1000) { // 1 second cooldown
            return false
        }
        lastDetectionTime = now

        return isExternalDisplayConnected() || isScreenRecordingActive()
    }

    private fun isExternalDisplayConnected(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                val displayManager = getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
                val displays = displayManager.displays
                return displays.any { it.displayId != Display.DEFAULT_DISPLAY && it.isValid }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking external displays", e)
            }
        }
        return false
    }

    private fun isScreenRecordingPossible(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                true
            } catch (e: Exception) {
                Log.e(TAG, "Error checking recording capability", e)
                false
            }
        } else {
            false
        }
    }

    private fun isScreenRecordingActive(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                // Check for active screen capture via MediaProjection
                val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

                // Check if screen capture intent would resolve (indicates recording capability is being used)
                val captureIntent = mediaProjectionManager.createScreenCaptureIntent()
                val resolveInfo = packageManager.resolveActivity(
                    captureIntent,
                    PackageManager.MATCH_DEFAULT_ONLY
                )

                // Additional checks for common recording apps
                if (resolveInfo != null) {
                    val packageName = resolveInfo.activityInfo.packageName
                    Log.d(TAG, "Screen capture intent resolved to: $packageName")
                    return isKnownRecordingApp(packageName)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking screen recording status", e)
            }
        }
        return false
    }

    private fun isKnownRecordingApp(packageName: String): Boolean {
        val recordingApps = listOf(
            "com.google.android.apps.screenrecorder",
            "com.hecorat.screenrecorder.free",
            "com.icecoldapps.screenrecorder",
            "com.kimcy929.screenrecorder",
            "com.llamalab.automate" // Some automation apps can record
        )
        return recordingApps.contains(packageName) ||
                packageName.startsWith("com.screen.recorder") ||
                packageName.contains("recorder")
    }

    private fun getSecurityStatus(): Map<String, Any> {
        return mapOf(
            "isSecure" to (window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE != 0),
            "isExternalDisplayConnected" to isExternalDisplayConnected(),
            "isScreenRecordingPossible" to isScreenRecordingPossible(),
            "isScreenRecordingActive" to isScreenRecordingActive(),
            "androidVersion" to Build.VERSION.SDK_INT
        )
    }

    // Optional: Override onWindowFocusChanged for additional security checks
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) {
            // Window lost focus - could indicate screen sharing or overlay
            Log.d(TAG, "Window focus lost - possible screen sharing")
        }
    }
}