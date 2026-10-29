package com.example.photo_position

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.WindowInsets
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Tells the overlay's Flutter engine the real screen geometry (in dp).
 *
 * The overlay is a system window whose Flutter engine keeps reporting the
 * display size it had at creation, so Dart cannot detect rotation or learn
 * the new size on its own. The engine is the one `flutter_overlay_window`
 * caches under [OVERLAY_ENGINE_TAG]. Dart can pull ("getScreen", used at
 * start) and is pushed ("screenChanged") on every configuration change.
 *
 * `shiftX/shiftY` is where the centre of the window's parent frame lies
 * relative to the screen centre: the plugin positions its `Gravity.CENTER`
 * window against a parent that excludes the navigation bar, so the shift
 * is needed to turn "pixels from the screen corner" into the plugin's offset.
 */
class ScreenSizeBridge : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val engine = FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_TAG) ?: return
        attach(context)
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .invokeMethod("screenChanged", describe(context))
    }

    companion object {
        private const val OVERLAY_ENGINE_TAG = "myCachedEngine"
        private const val CHANNEL = "photo_position/screen"

        fun register(context: Context) {
            val filter = IntentFilter(Intent.ACTION_CONFIGURATION_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(ScreenSizeBridge(), filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                context.registerReceiver(ScreenSizeBridge(), filter)
            }
        }

        /**
         * Lets the overlay engine pull the screen geometry. The main app calls
         * this right after showOverlay; the cached engine appears shortly
         * after, so this retries for ~10s. Safe to call repeatedly.
         */
        fun attach(context: Context, attemptsLeft: Int = 50) {
            val engine = FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_TAG)
            if (engine == null) {
                // The plugin creates its engine asynchronously after showOverlay.
                if (attemptsLeft > 0) {
                    Handler(Looper.getMainLooper()).postDelayed({ attach(context, attemptsLeft - 1) }, 200)
                }
                return
            }
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "getScreen") result.success(describe(context)) else result.notImplemented()
            }
        }

        private fun describe(context: Context): Map<String, Double> {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val density = context.resources.displayMetrics.density.toDouble()
            var shiftX = 0.0
            var shiftY = 0.0
            val w: Int
            val h: Int
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val metrics = wm.maximumWindowMetrics
                w = metrics.bounds.width()
                h = metrics.bounds.height()
                val nav = metrics.windowInsets.getInsetsIgnoringVisibility(WindowInsets.Type.navigationBars())
                shiftX = (nav.left - nav.right) / 2.0
                shiftY = (nav.top - nav.bottom) / 2.0
            } else {
                val m = DisplayMetrics()
                @Suppress("DEPRECATION") wm.defaultDisplay.getRealMetrics(m)
                w = m.widthPixels
                h = m.heightPixels
            }
            return mapOf(
                "width" to w / density,
                "height" to h / density,
                "shiftX" to shiftX / density,
                "shiftY" to shiftY / density,
            )
        }
    }
}
