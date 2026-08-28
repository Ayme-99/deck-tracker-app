import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Resultado de comprobar si hay una version mas reciente publicada.
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;

  /// URL de descarga directa del instalador (.exe) o APK (.apk) para la
  /// plataforma actual (issue #248). Null si no se encontro un asset que
  /// coincida (release sin ese build, o plataforma no soportada) -- en ese
  /// caso solo cabe enlazar a GitHub como ya se hacia antes de la #248.
  final String? downloadUrl;
  final String? downloadFileName;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    this.downloadUrl,
    this.downloadFileName,
  });
}

/// Comprobacion de nueva version disponible (issue #233), consultando
/// directamente la API publica de GitHub releases -- no requiere ningun
/// endpoint propio en el servidor.
class UpdateCheckService {
  static const _releasesApiUrl =
      'https://api.github.com/repos/Ayme-99/deck-tracker-app/releases/latest';

  /// Extension de asset a buscar segun la plataforma actual. Null en web
  /// (no aplica descargar/instalar nada, ver notas de alcance de la #233).
  String? get _assetExtension {
    if (kIsWeb) return null;
    if (Platform.isWindows) return '.exe';
    if (Platform.isAndroid) return '.apk';
    return null;
  }

  /// Devuelve null si ya se tiene la ultima version, o si la comprobacion
  /// falla por cualquier motivo (sin red, rate limit de la API de GitHub,
  /// formato inesperado...) -- nunca debe bloquear el arranque de la app.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      final response = await http.get(Uri.parse(_releasesApiUrl));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String?;
      final releaseUrl = data['html_url'] as String?;
      if (tagName == null || releaseUrl == null) return null;

      // Los tags publicados llevan el prefijo "v" (ej. "v1.4.0+1")
      final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;

      if (latestVersion == currentVersion) return null;

      final extension = _assetExtension;
      String? downloadUrl;
      String? downloadFileName;

      if (extension != null) {
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String?;
          if (name != null && name.toLowerCase().endsWith(extension)) {
            downloadUrl = asset['browser_download_url'] as String?;
            downloadFileName = name;
            break;
          }
        }
      }

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
        downloadUrl: downloadUrl,
        downloadFileName: downloadFileName,
      );
    } catch (_) {
      return null;
    }
  }
}