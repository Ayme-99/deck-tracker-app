import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/backup_service.dart';
import '../../services/file_export_service.dart';

/// Backup/restore completo de la cuenta (issue #165): mazos + partidas +
/// torneos tracked, en un unico JSON. Torneos hosted quedan fuera de
/// alcance (ver comentario en BackupService).
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backupService = BackupService();
  final _fileExportService = FileExportService();

  bool _isExporting = false;
  bool _isRestoring = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final backup = await _backupService.buildBackup();
      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final fileName = 'deck_tracker_backup_${DateTime.now().toIso8601String().substring(0, 10)}';
      final exported = await _fileExportService.saveJson(json, fileName);

      if (!mounted) return;
      final decks = (backup['decks'] as List).length;
      final tournaments = (backup['tournaments'] as List).length;
      final matches = (backup['matches'] as List).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup exportado: $decks mazos, $tournaments torneos, $matches partidas'),
          action: SnackBarAction(label: 'Abrir', onPressed: () => _fileExportService.open(exported)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null || !mounted) return;

    // Issue #197: se parsea el JSON ANTES del dialogo de confirmacion para
    // poder mostrar cuantas entidades contiene -- antes no habia forma de
    // detectar un archivo equivocado o corrupto hasta despues de restaurar.
    late final Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El archivo no es un backup válido (JSON corrupto)')),
      );
      return;
    }

    final deckCount = (data['decks'] as List?)?.length ?? 0;
    final matchCount = (data['matches'] as List?)?.length ?? 0;
    final tournamentCount = (data['tournaments'] as List?)?.length ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar backup'),
        content: Text(
          'Vas a añadir $deckCount mazos, $matchCount partidas y $tournamentCount torneos a tu '
          'cuenta actual como entidades nuevas -- no sobrescribe ni borra nada de lo que ya '
          'tengas. Si restauras el mismo backup dos veces, tendrás los mazos duplicados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      final summary = await _backupService.restoreBackup(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restaurado: ${summary.decks} mazos, ${summary.tournaments} torneos, ${summary.matches} partidas',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al restaurar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copia de seguridad')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exporta todos tus mazos, partidas y torneos seguidos (no alojados) a un único '
              'archivo, para migrar de cuenta o tener una copia de seguridad manual.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.spacingL),
            FilledButton.icon(
              onPressed: _isExporting || _isRestoring ? null : _handleExport,
              icon: _isExporting
                  ? const SizedBox(
                      height: AppSizes.spinnerSmall,
                      width: AppSizes.spinnerSmall,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined),
              label: const Text('Exportar backup'),
            ),
            const SizedBox(height: AppSizes.spacingM),
            OutlinedButton.icon(
              onPressed: _isExporting || _isRestoring ? null : _handleRestore,
              icon: _isRestoring
                  ? const SizedBox(
                      height: AppSizes.spinnerSmall,
                      width: AppSizes.spinnerSmall,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: const Text('Restaurar desde archivo'),
            ),
          ],
        ),
      ),
    );
  }
}
