package app.luma.calculator

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferences = getSharedPreferences("luma_state", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.luma.calculator/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "read" -> result.success(preferences.getString("state", null))
                    "write" -> {
                        val state = call.arguments as? String
                        if (state == null || state.length > 262144) {
                            result.error("INVALID_STATE", "State is invalid", null)
                        } else {
                            preferences.edit().putString("state", state).apply()
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
