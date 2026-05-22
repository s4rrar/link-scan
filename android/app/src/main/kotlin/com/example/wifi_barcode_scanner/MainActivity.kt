package com.example.wifi_barcode_scanner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.AudioManager
import android.media.ToneGenerator

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.wifi_barcode_scanner/beep"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "beep") {
                try {
                    val toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
                    toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 150)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("BEEP_FAILED", "Failed to play beep: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}

