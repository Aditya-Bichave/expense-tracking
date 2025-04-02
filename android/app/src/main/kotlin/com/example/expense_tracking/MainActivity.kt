package com.example.expense_tracking // <<<--- Make sure this matches your actual package name

// Import FlutterFragmentActivity instead of FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.embedding.engine.FlutterEngine

// Extend FlutterFragmentActivity instead of FlutterActivity
class MainActivity: FlutterFragmentActivity() {
    // This method registers plugins.
    // It's optional if you don't have platform channels defined directly in MainActivity,
    // but generally good practice to keep for GeneratedPluginRegistrant.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        // You can register other platform channels here if needed
    }
}