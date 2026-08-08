package com.dg.developer.exitplan

import android.app.AlarmManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * AudioServiceActivity instead of FlutterActivity: audio_service needs the
 * activity to hand it the right FlutterEngine so the media session can be bound
 * from a cold start.
 *
 * On top of that it answers the three questions Dart cannot ask for itself, and
 * performs the one action that has to happen on a real Activity: showing a fake
 * incoming call over the lock screen.
 *
 * There is deliberately **no second Activity** for the call. A dedicated one
 * would need its own FlutterEngine and would duplicate the audio_service
 * binding, for the sake of a window flag that can be set and unset on this one.
 */
class MainActivity : AudioServiceActivity() {

    private companion object {
        const val CHANNEL = "exitplan/calls"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canScheduleExactAlarms" -> result.success(canScheduleExactAlarms())
            "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
            "isIgnoringBatteryOptimizations" ->
                result.success(isIgnoringBatteryOptimizations())

            "openExactAlarmSettings" -> {
                openExactAlarmSettings()
                result.success(null)
            }

            "openFullScreenIntentSettings" -> {
                openFullScreenIntentSettings()
                result.success(null)
            }

            "openBatterySettings" -> {
                openBatterySettings()
                result.success(null)
            }

            "setLockScreenMode" -> {
                setLockScreenMode(call.arguments as? Boolean ?: false)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Below Android 12 exact alarms need no permission, so there is nothing to
     * be denied and the honest answer is yes.
     */
    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarms = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarms.canScheduleExactAlarms()
    }

    /**
     * Below Android 14 this is an install-time permission and is simply held.
     * From 14 the system withholds it from apps that are not phone or alarm
     * apps — which this is not, and does not claim to be — so it has to be
     * granted by hand.
     */
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        return NotificationManagerCompat.from(this).canUseFullScreenIntent()
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        startSafely(
            Intent(
                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                Uri.parse("package:$packageName"),
            )
        )
    }

    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        startSafely(
            Intent(
                Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                Uri.parse("package:$packageName"),
            )
        )
    }

    /**
     * The *list*, not the "please exempt me" dialog.
     *
     * ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS pops a system prompt and is
     * restricted by Play policy to apps whose core function genuinely cannot
     * work without it. This app's calls are late without the exemption, not
     * absent, so it sends the user to the settings list and lets them decide.
     */
    private fun openBatterySettings() {
        startSafely(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    }

    /**
     * Turns this Activity into one that can appear over the lock screen and
     * wake the display, and turns it back off again.
     *
     * Held only while a call screen is mounted. Leaving it on permanently would
     * mean the launcher icon opens an app that sits over the keyguard, which is
     * both wrong and the kind of thing that gets noticed in review.
     */
    private fun setLockScreenMode(enabled: Boolean) {
        runOnUiThread {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(enabled)
                setTurnScreenOn(enabled)
            } else {
                @Suppress("DEPRECATION")
                val flags =
                    android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                if (enabled) window.addFlags(flags) else window.clearFlags(flags)
            }

            if (enabled) {
                val keyguard =
                    getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    keyguard.requestDismissKeyguard(this, null)
                }
            }
        }
    }

    /**
     * Every settings screen above is optional on some OEM builds and absent on
     * others. A missing one must not crash the app the user opened to arrange
     * a way out of a meeting.
     */
    private fun startSafely(intent: Intent) {
        try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (_: Exception) {
            // Nothing to fall back to, and nothing worth crashing over.
        }
    }
}
