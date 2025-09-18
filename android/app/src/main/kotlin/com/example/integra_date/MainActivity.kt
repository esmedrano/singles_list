package com.example.integra_date

import io.flutter.embedding.android.FlutterActivity

import android.content.Intent

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // Update the activity's intent
        // Notify Flutter of the new intent (app_links handles this automatically)
    }
}