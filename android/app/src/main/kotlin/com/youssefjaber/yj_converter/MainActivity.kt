package com.youssefjaber.yj_converter

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val mediaScannerChannel = "yj_converter/media_scanner"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaScannerChannel)
      .setMethodCallHandler { call, result ->
        if (call.method == "scanFile") {
          val path = call.argument<String>("path")
          if (path == null) {
            result.error("NO_PATH", "Path is required", null)
            return@setMethodCallHandler
          }
          MediaScannerConnection.scanFile(this, arrayOf(path), null, null)
          result.success(true)
        } else {
          result.notImplemented()
        }
      }
  }
}
