package com.dg.developer.exitplan

import android.app.AlarmManager
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * AudioServiceActivity instead of FlutterActivity: audio_service needs the
 * activity to hand it the right FlutterEngine so the media session can be bound
 * from a cold start.
 *
 * On top of that it answers the two questions Dart cannot ask for itself, and
 * performs the one action that has to happen on a real Activity: showing a fake
 * incoming call over the lock screen.
 *
 * That last part still works without `USE_FULL_SCREEN_INTENT`, and the
 * distinction is worth stating because the permission's removal looks like it
 * should have taken it with it. `setShowWhenLocked`/`setTurnScreenOn` are
 * window flags on an Activity that is *already being started*; the permission
 * only governs whether Android may start it **unprompted**. So the call screen
 * still covers the keyguard exactly as before — it is now reached by tapping
 * the notification rather than by the system launching it on its own.
 *
 * There is deliberately **no second Activity** for the call. A dedicated one
 * would need its own FlutterEngine and would duplicate the audio_service
 * binding, for the sake of a window flag that can be set and unset on this one.
 */
class MainActivity : AudioServiceActivity() {

    private companion object {
        const val CHANNEL = "exitplan/calls"

        /**
         * The extra flutter_local_notifications puts on the launch intent. Its
         * presence is how this Activity knows, natively and immediately, that
         * it is being started by a scheduled call rather than by the user.
         */
        const val NOTIFICATION_PAYLOAD = "payload"
    }

    /**
     * Set here rather than from Dart, and that ordering is the whole point.
     *
     * `setLockScreenMode` below is still called from Dart, but on a cold start
     * it arrives far too late to matter: Android launches this Activity, then
     * the Flutter engine boots, then `main()` runs, then `AppState.bootstrap()`
     * resolves, and only then does any Dart get to ask for these flags. By that
     * point the window has already been placed — behind the keyguard, with the
     * display still off. The call rang into a phone showing its lock screen.
     *
     * Doing it in `onCreate` puts the flags on before the first frame.
     *
     * Deliberately **not** `android:showWhenLocked="true"` in the manifest,
     * which is the one-line version of this fix. MainActivity is the launcher
     * activity, so a permanent flag means that locking the phone with ExitPlan
     * in the foreground leaves the app sitting on top of the lock screen — the
     * opposite of what this app is for.
     */
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (isCallLaunch(intent)) setLockScreenMode(true)
    }

    /**
     * The warm path: the process was already alive and Android delivered the
     * full-screen intent to the existing Activity instead of creating one.
     * `launchMode="singleTop"` is what routes it here.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (isCallLaunch(intent)) setLockScreenMode(true)
    }

    private fun isCallLaunch(intent: Intent?): Boolean =
        intent?.hasExtra(NOTIFICATION_PAYLOAD) == true

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canScheduleExactAlarms" -> result.success(canScheduleExactAlarms())
            "isIgnoringBatteryOptimizations" ->
                result.success(isIgnoringBatteryOptimizations())

            "openExactAlarmSettings" -> {
                openExactAlarmSettings()
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
