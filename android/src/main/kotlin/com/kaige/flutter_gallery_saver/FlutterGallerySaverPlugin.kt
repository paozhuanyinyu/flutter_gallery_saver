package com.kaige.flutter_gallery_saver

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/** FlutterGallerySaverPlugin */
class FlutterGallerySaverPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context : Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "kaige.com/gallery_saver")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when(call.method) {
      "saveImageToGallery" -> {
        val image = call.argument<ByteArray>("imageBytes") ?: return
        val quality = call.argument<Int>("quality") ?: return
        val albumName = call.argument<String>("albumName")
        result.success(saveImageToGallery(BitmapFactory.decodeByteArray(image, 0, image.size), quality, albumName))
      }
      "saveFileToGallery" -> {
        val path = call.argument<String>("filePath") ?: return
        val albumName = call.argument<String>("albumName")
        result.success(saveFileToGallery(path, albumName))
      }
      "galleryFileExists" -> {
        val uri = call.argument<String>("uri") ?: return
        var isExists: Boolean = false
        var msg: String = "success"
        try {
          println("uri: $uri")
          val filePath = Uri.parse(uri).path
          println("filePath: $filePath")
          val file: File = File(filePath)
          isExists = file.exists()
        }catch (e: Exception){
          e.printStackTrace()
          msg = e.toString()
        }
        val resultMap = mutableMapOf("isExists" to isExists, "uri" to uri, "msg" to msg)
        result.success(resultMap)
      }
      else -> result.notImplemented()
    }
  }
  private fun generateFile(extension: String = "", albumName: String): File {
    val storePath =  Environment.getExternalStorageDirectory().absolutePath + File.separator + albumName
    val appDir = File(storePath)
    if (!appDir.exists()) {
      appDir.mkdir()
    }
    var fileName = System.currentTimeMillis().toString()
    if (extension.isNotEmpty()) {
      fileName += (".$extension")
    }
    return File(appDir, fileName)
  }

  private fun saveImageToGallery(bmp: Bitmap, quality: Int, albumName: String?): String {
    val file = generateFile("jpg", albumName ?: getApplicationName())
    try {
      val fos = FileOutputStream(file)
      println("ImageGallerySaverPlugin $quality")
      bmp.compress(Bitmap.CompressFormat.JPEG, quality, fos)
      fos.flush()
      fos.close()
      var uri= Uri.fromFile(file)
      context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
      bmp.recycle()
      return uri.toString()
    } catch (e: IOException) {
      e.printStackTrace()
    }
    return ""
  }

  private fun saveFileToGallery(filePath: String, albumName: String?): String {
    return try {
      val originalFile = File(filePath)
      val file = generateFile(originalFile.extension, albumName ?: getApplicationName())
      originalFile.copyTo(file)
      var uri= Uri.fromFile(file)
      context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
      return uri.toString()
    } catch (e: IOException) {
      e.printStackTrace()
      ""
    }
  }

  private fun getApplicationName(): String {
    var ai: ApplicationInfo? = null
    try {
      ai = context.packageManager.getApplicationInfo(context.packageName, 0)
    } catch (e: PackageManager.NameNotFoundException) {
    }
    var appName: String
    appName = if (ai != null) {
      val charSequence = context.packageManager.getApplicationLabel(ai)
      StringBuilder(charSequence.length).append(charSequence).toString()
    } else {
      "flutter_gallery_saver"
    }
    return appName
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
