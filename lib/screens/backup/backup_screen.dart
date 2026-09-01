import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/backup_service.dart';
import '../../services/file_export_service.dart';
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
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
          content: Text(l10n.backupExportedSnackbar(decks, tournaments, matches)),
          action: SnackBarAction(label: l10n.backupOpenAction, onPressed: () => _fileExportService.open(exported)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupExportError(e.toString().replaceFirst('Exception: ', '')))),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleRestore() async {
    final l10n = AppLocalizations.of(context);
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
        SnackBar(content: Text(l10n.backupInvalidFile)),
      );
      return;
    }

    final deckCount = (data['decks'] as List?)?.length ?? 0;
    final matchCount = (data['matches'] as List?)?.length ?? 0;
    final tournamentCount = (data['tournaments'] as List?)?.length ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupRestoreDialogTitle),
        content: Text(l10n.backupRestoreDialogContent(deckCount, matchCount, tournamentCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.backupRestoreAction),
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
          content: Text(l10n.backupRestoredSnackbar(summary.decks, summary.tournaments, summary.matches)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupRestoreError(e.toString().replaceFirst('Exception: ', '')))),
      );
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupScreenTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupDescription,
              style: const TextStyle(color: AppColors.textSecondary),
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
              label: Text(l10n.backupExportButton),
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
              label: Text(l10n.backupRestoreButton),
            ),
          ],
        ),
      ),
    );
  }
}
