package com.example.photo_position

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        // Called by the main app right after it shows the overlay.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "photo_position/host")
            .setMethodCallHandler { call, result ->
                if (call.method == "attachScreenBridge") {
                    ScreenSizeBridge.attach(applicationContext)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
