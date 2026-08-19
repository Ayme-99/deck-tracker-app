package com.example.deck_tracker_app

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Canal nativo para guardar archivos exportados directamente en la carpeta
 * publica de Descargas via MediaStore (issue #162): el plugin file_saver
 * solo escribe en el almacenamiento privado de la app
 * (Android/data/<paquete>/files/), nunca en Descargas de verdad -- se
 * comprobo leyendo su codigo nativo (usa getExternalFilesDir). MediaStore.
 * Downloads es la via recomendada por Android 10+ para escribir en Descargas
 * sin pedir permisos de almacenamiento.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "deck_tracker/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "saveToDownloads" -> {
                        val fileName = call.argument<String>("fileName")!!
                        val mimeType = call.argument<String>("mimeType")!!
                        val bytes = call.argument<ByteArray>("bytes")!!
                        result.success(saveToDownloads(fileName, mimeType, bytes))
                    }
                    "openContentUri" -> {
                        val uriString = call.argument<String>("uri")!!
                        val mimeType = call.argument<String>("mimeType")!!
                        openContentUri(uriString, mimeType)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("SAVE_FAILED", e.message, null)
            }
        }
    }

    /** Devuelve el content:// URI del archivo ya insertado en Descargas. */
    private fun saveToDownloads(fileName: String, mimeType: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw Exception("Requiere Android 10 o superior")
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
        }

        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw Exception("No se pudo crear el archivo en Descargas")

        contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
            ?: throw Exception("No se pudo abrir el archivo para escribir")

        return uri.toString()
    }

    private fun openContentUri(uriString: String, mimeType: String) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(uriString), mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(Intent.createChooser(intent, null))
    }
}
