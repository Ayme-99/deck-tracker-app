import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Descarga el instalador (.exe) o APK (.apk) de la nueva version en
/// segundo plano y lo ejecuta/instala (issue #248, paso intermedio al
/// auto-update completo -- ver notas de alcance de la issue sobre por que
/// se descarto el auto-update de verdad).
class UpdateDownloadService {
  static const _channel = MethodChannel('deck_tracker/downloads');

  /// Descarga [downloadUrl] a un directorio temporal, reportando progreso
  /// 0.0-1.0 via [onProgress] (null si el servidor no informa el tamaño
  /// total -- Content-Length ausente). Devuelve la ruta local del archivo.
  Future<String> download(
    String downloadUrl,
    String fileName, {
    void Function(double? progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    final request = http.Request('GET', Uri.parse(downloadUrl));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw Exception('Descarga fallida (HTTP ${response.statusCode})');
    }

    final total = response.contentLength;
    var received = 0;
    final sink = file.openWrite();

    await response.stream.map((chunk) {
      received += chunk.length;
      onProgress?.call(total != null ? received / total : null);
      return chunk;
    }).pipe(sink);

    return filePath;
  }

  /// Lanza el instalador ya descargado. En Windows ejecuta el .exe
  /// directamente; en Android delega en el canal nativo, que comprueba el
  /// permiso "Instalar apps desconocidas" antes de abrir el instalador del
  /// sistema (ver MainActivity.kt).
  Future<void> runInstaller(String filePath) async {
    if (Platform.isWindows) {
      await Process.start(filePath, [], mode: ProcessStartMode.detached);
      return;
    }

    if (Platform.isAndroid) {
      await _channel.invokeMethod('installApk', {'path': filePath});
      return;
    }

    throw UnsupportedError('Plataforma no soportada para instalar automaticamente');
  }

  /// Solo relevante en Android: si el usuario aun no ha concedido permiso
  /// para instalar apps de origenes desconocidos, hay que enviarlo a los
  /// ajustes del sistema antes de poder lanzar el instalador.
  Future<bool> canInstallPackages() async {
    if (!Platform.isAndroid) return true;
    final result = await _channel.invokeMethod<bool>('canInstallPackages');
    return result ?? false;
  }

  /// Abre la pantalla de ajustes del sistema donde se concede el permiso
  /// de "Instalar apps desconocidas" para esta app.
  Future<void> requestInstallPermission() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('requestInstallPermission');
  }
}