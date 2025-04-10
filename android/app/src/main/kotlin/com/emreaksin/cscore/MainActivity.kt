package com.emreaksin.cscore

import android.content.Context
import android.os.Bundle
import android.view.WindowManager
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.os.Build
import android.view.WindowInsets
import android.view.WindowInsetsController

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Hemen başlangıçta normal temayı uygula, böylece splash screen'i atla
        setTheme(R.style.NormalTheme)
        
        super.onCreate(savedInstanceState)
        
        // Tam ekran modu ayarla
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let {
                it.hide(WindowInsets.Type.statusBars())
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            )
        }
        
        // Ekranı siyah yap
        window.statusBarColor = 0xFF000000.toInt()
        window.navigationBarColor = 0xFF000000.toInt()
    }
}
