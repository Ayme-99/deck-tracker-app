import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/update_check_service.dart';
import '../../services/update_download_service.dart';

/// Dialogo de aviso de nueva version (issue #233), ampliado en la #248 para
/// descargar el instalador/APK en segundo plano y ofrecer ejecutarlo, en
/// vez de solo enlazar a la pagina de la release.
///
/// Estados: [_idle] (aviso inicial) -> [_downloading] (progreso) ->
/// [_ready] (boton "Ejecutar instalador"/"Instalar") -> [_error] (algo
/// fallo, se mantiene el enlace a GitHub como alternativa siempre visible).
enum _UpdateDialogState { idle, downloading, ready, error }

class UpdateDialog extends StatefulWidget {
  final UpdateInfo update;

  const UpdateDialog({super.key, required this.update});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState_();
}

class _UpdateDialogState_ extends State<UpdateDialog> {
  final _downloadService = UpdateDownloadService();

  _UpdateDialogState _state = _UpdateDialogState.idle;
  double? _progress;
  String? _installerPath;

  Future<void> _startDownload() async {
    setState(() {
      _state = _UpdateDialogState.downloading;
      _progress = null;
    });

    try {
      // En Android, comprobar el permiso de "instalar apps desconocidas"
      // antes de descargar -- evita descargar en balde si no se va a poder
      // instalar despues.
      if (!await _downloadService.canInstallPackages()) {
        await _downloadService.requestInstallPermission();
        // El usuario vuelve de Ajustes sin que sepamos si concedio el
        // permiso; se deja el boton "Ejecutar instalador" disponible igual,
        // el propio instalador nativo volvera a pedirlo si sigue sin estar.
      }

      final path = await _downloadService.download(
        widget.update.downloadUrl!,
        widget.update.downloadFileName!,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
      );

      if (!mounted) return;
      setState(() {
        _installerPath = path;
        _state = _UpdateDialogState.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _UpdateDialogState.error);
    }
  }

  Future<void> _runInstaller() async {
    try {
      await _downloadService.runInstaller(_installerPath!);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _UpdateDialogState.error);
    }
  }

  void _openInGitHub() {
    launchUrl(Uri.parse(widget.update.releaseUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasDownload = widget.update.downloadUrl != null;

    return AlertDialog(
      title: const Text('Nueva versión disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tienes la versión ${widget.update.currentVersion} instalada. '
            'Ya está disponible la ${widget.update.latestVersion}.',
          ),
          if (_state == _UpdateDialogState.downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
          if (_state == _UpdateDialogState.error) ...[
            const SizedBox(height: 16),
            Text(
              'No se pudo descargar el instalador. Puedes descargarlo a mano desde GitHub.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ahora no'),
        ),
        TextButton(
          onPressed: _openInGitHub,
          child: const Text('Ver en GitHub'),
        ),
        if (_state == _UpdateDialogState.ready)
          FilledButton(
            onPressed: _runInstaller,
            child: const Text('Ejecutar instalador'),
          )
        else if (hasDownload)
          FilledButton(
            onPressed: _state == _UpdateDialogState.downloading ? null : _startDownload,
            child: const Text('Actualizar'),
          ),
      ],
    );
  }
}