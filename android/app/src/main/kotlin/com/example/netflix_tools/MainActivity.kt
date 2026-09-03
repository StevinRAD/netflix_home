package com.example.netflix_tools

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.netflix_tools/netflix_launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchNetflixApp") {
                val nftoken = call.argument<String>("nftoken") ?: ""
                val success = launchNetflixDirectly(nftoken)
                result.success(success)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchNetflixDirectly(nftoken: String): Boolean {
        val netflixPkg = "com.netflix.mediaclient"
        
        // 1. Try nflx:// scheme without package restriction first (most reliable for deep linking if registered)
        try {
            val intent1 = Intent(Intent.ACTION_VIEW, Uri.parse("nflx://www.netflix.com/unsupported?nftoken=$nftoken")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent1.resolveActivity(packageManager) != null) {
                startActivity(intent1)
                return true
            }
        } catch (e: Exception) {}

        // 2. Try netflix:// scheme
        try {
            val intent2 = Intent(Intent.ACTION_VIEW, Uri.parse("netflix://www.netflix.com/unsupported?nftoken=$nftoken")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent2.resolveActivity(packageManager) != null) {
                startActivity(intent2)
                return true
            }
        } catch (e: Exception) {}

        // 3. Try standard https with explicit package targeting (Force opening Netflix)
        try {
            val intent3 = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.netflix.com/unsupported?nftoken=$nftoken")).apply {
                setPackage(netflixPkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent3)
            return true
        } catch (e: Exception) {}

        return false
    }
}
