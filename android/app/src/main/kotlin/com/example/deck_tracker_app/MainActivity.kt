package com.example.deck_tracker_app

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Canal nativo para guardar archivos exportados directamente en la carpeta
 * publica de Descargas via MediaStore (issue #162), y para descargar en
 * segundo plano e instalar el APK de una nueva version (issue #248).
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
                    // issue #248 --------------------------------------------------
                    "canInstallPackages" -> {
                        result.success(canInstallPackages())
                    }
                    "requestInstallPermission" -> {
                        requestInstallPermission()
                        result.success(null)
                    }
                    "installApk" -> {
                        val path = call.argument<String>("path")!!
                        installApk(path)
                        result.success(null)
                    }
                    // ---------------------------------------------------------------
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

    // issue #248 ------------------------------------------------------------

    /** Si la app ya tiene permiso para instalar apps de origenes desconocidos. */
    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true // en Android < 8 el permiso es a nivel de sistema, no por app
        }
    }

    /** Abre los ajustes del sistema donde el usuario concede ese permiso. */
    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val intent = Intent(android.provider.Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        }
    }

    /**
     * Lanza el instalador del sistema para el APK ya descargado en el
     * almacenamiento privado de la app (ver UpdateDownloadService, guarda en
     * getTemporaryDirectory). Requiere un FileProvider (ver notas mas abajo)
     * porque a partir de Android 7 no se puede compartir un file:// URI
     * directamente entre apps.
     */
    private fun installApk(path: String) {
        val file = File(path)
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}