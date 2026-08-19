import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';

/// Resultado de guardar un archivo exportado: [uri] si se guardo via
/// MediaStore (Android, issue #162 -- content:// URI en Descargas de
/// verdad), o [path] si se guardo via file_saver (resto de plataformas).
class ExportedFile {
  final String? uri;
  final String? path;
  final String mimeType;

  ExportedFile.fromUri(this.uri, this.mimeType) : path = null;
  ExportedFile.fromPath(this.path, this.mimeType) : uri = null;
}

/// Guarda archivos exportados directamente en el dispositivo (issue #162,
/// ampliado en #165 para JSON), en vez de pasar por el share sheet.
///
/// En Android usa un canal nativo propio (ver MainActivity.kt) que escribe
/// via MediaStore.Downloads: es la unica forma de que el archivo aparezca
/// de verdad en la carpeta publica de Descargas en Android 10+ sin pedir
/// permisos de almacenamiento. file_saver (usado en el resto de
/// plataformas) NO sirve para esto en Android: su codigo nativo escribe
/// siempre en el almacenamiento privado de la app
/// (Android/data/`paquete`/files/), nunca en Descargas -- se comprobo
/// leyendo su fuente.
class FileExportService {
  static const _channel = MethodChannel('deck_tracker/downloads');

  Future<ExportedFile> saveFile(
    String content,
    String fileName, {
    required String ext,
    required String mimeType,
    required MimeType fileSaverMimeType,
  }) async {
    final bytes = utf8.encode(content);

    if (!kIsWeb && Platform.isAndroid) {
      final uri = await _channel.invokeMethod<String>('saveToDownloads', {
        'fileName': '$fileName.$ext',
        'mimeType': mimeType,
        'bytes': bytes,
      });
      return ExportedFile.fromUri(uri!, mimeType);
    }

    final path = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: ext,
      mimeType: fileSaverMimeType,
    );
    return ExportedFile.fromPath(path, mimeType);
  }

  Future<ExportedFile> saveCsv(String csvContent, String fileName) {
    return saveFile(csvContent, fileName, ext: 'csv', mimeType: 'text/csv', fileSaverMimeType: MimeType.csv);
  }

  Future<ExportedFile> saveJson(String jsonContent, String fileName) {
    return saveFile(jsonContent, fileName, ext: 'json', mimeType: 'application/json', fileSaverMimeType: MimeType.json);
  }

  Future<void> open(ExportedFile file) async {
    if (file.uri != null) {
      await _channel.invokeMethod('openContentUri', {
        'uri': file.uri,
        'mimeType': file.mimeType,
      });
    } else if (file.path != null) {
      // Se fuerza el MIME type: open_filex adivina ".csv" como
      // "application/vnd.ms-excel" (XLS binario) por defecto, y algunos
      // visores (Sheets, Excel) lo interpretan como XLS de verdad y dicen
      // que el archivo esta "dañado" al no serlo.
      await OpenFilex.open(file.path!, type: file.mimeType);
    }
  }
}
