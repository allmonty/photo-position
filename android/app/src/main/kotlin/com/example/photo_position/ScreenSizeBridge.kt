package com.example.photo_position

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.DisplayMetrics
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Tells the overlay's Flutter engine the real screen size (in dp) whenever the
 * display rotates.
 *
 * The overlay is a system window whose Flutter engine keeps reporting the
 * display size it had at creation, so Dart cannot detect rotation or learn
 * the new size on its own. The engine is the one `flutter_overlay_window`
 * caches under [OVERLAY_ENGINE_TAG].
 */
class ScreenSizeBridge : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val engine = FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_TAG) ?: return
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .invokeMethod("screenChanged", screenSizeDp(context))
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

        /** Full display including system bars, the space the overlay window is positioned in. */
        private fun screenSizeDp(context: Context): Map<String, Double> {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val density = context.resources.displayMetrics.density
            val (w, h) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val b = wm.maximumWindowMetrics.bounds
                b.width() to b.height()
            } else {
                val m = DisplayMetrics()
                @Suppress("DEPRECATION") wm.defaultDisplay.getRealMetrics(m)
                m.widthPixels to m.heightPixels
            }
            return mapOf("width" to w / density.toDouble(), "height" to h / density.toDouble())
        }
    }
}
