import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Resultado de comprobar si hay una version mas reciente publicada.
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
  });
}

/// Comprobacion de nueva version disponible (issue #233), consultando
/// directamente la API publica de GitHub releases -- no requiere ningun
/// endpoint propio en el servidor. Alcance deliberadamente simple: solo
/// avisa y enlaza a la pagina de la release, no descarga ni instala nada
/// (ver notas de alcance de la issue para las opciones mas complejas
/// descartadas por ahora).
class UpdateCheckService {
  static const _releasesApiUrl =
      'https://api.github.com/repos/Ayme-99/deck-tracker-app/releases/latest';

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

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseUrl: releaseUrl,
      );
    } catch (_) {
      return null;
    }
  }
}
