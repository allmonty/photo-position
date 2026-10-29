package com.example.photo_position

import android.app.Application

class PhotoPositionApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ScreenSizeBridge.register(this)
    }
}
