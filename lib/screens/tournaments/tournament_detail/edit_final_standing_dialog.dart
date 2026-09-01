import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/tournament.dart';
import '../../../l10n/app_localizations.dart';

/// Dialogo de edicion del puesto final (issue #256: extraido de
/// tournament_detail_screen.dart). Devuelve null si se cancela; si se
/// confirma, un record con `position`/`total` (ambos null si se dejaron
/// los dos campos vacios, para borrar la posicion guardada).
///
/// Issue #187: "Guardar" exige que ambos campos esten vacios (borra la
/// posicion) o sean numeros positivos validos -- antes se guardaba el
/// texto interpolado sin validar.
Future<({int? position, int? total})?> showEditFinalStandingDialog(
  BuildContext context, {
  required String? currentFinalStanding,
}) async {
  final parsed = parseFinalStanding(currentFinalStanding);
  final positionController = TextEditingController(text: parsed?.$1.toString() ?? '');
  final totalController = TextEditingController(text: parsed?.$2.toString() ?? '');

  bool isValid() {
    final position = positionController.text.trim();
    final total = totalController.text.trim();
    if (position.isEmpty && total.isEmpty) return true; // borra la posicion guardada
    final p = int.tryParse(position);
    final t = int.tryParse(total);
    return p != null && p > 0 && t != null && t > 0;
  }

  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(l10n.finalStandingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: positionController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.positionObtainedLabel),
              onChanged: (_) => setDialogState(() {}),
            ),
            const SizedBox(height: AppSizes.spacingM),
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.totalParticipantsLabel),
              onChanged: (_) => setDialogState(() {}),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelAction)),
          FilledButton(
            onPressed: isValid() ? () => Navigator.of(context).pop(true) : null,
            child: Text(l10n.saveAction),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return null;

  final position = positionController.text.trim();
  final total = totalController.text.trim();
  if (position.isEmpty || total.isEmpty) return (position: null, total: null);
  return (position: int.parse(position), total: int.parse(total));
}
