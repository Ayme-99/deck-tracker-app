import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../l10n/app_localizations.dart';

/// Dialogo para añadir un snapshot manual de posicion/puntos (issue #256:
/// extraido de tournament_detail_screen.dart). Solo tiene sentido en
/// torneos de tipo 'league': ahi no hay forma de derivar la clasificacion
/// a partir de las partidas propias, asi que el usuario la introduce a
/// mano cuando quiera. Devuelve null si se cancela.
Future<({int? points, int? position, String? notes})?> showAddStandingSnapshotDialog(BuildContext context) async {
  final pointsController = TextEditingController();
  final positionController = TextEditingController();
  final notesController = TextEditingController();

  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.addStandingTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: pointsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.pointsLabel),
          ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: positionController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.positionInTableLabel),
          ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: notesController,
            decoration: InputDecoration(labelText: l10n.notesOptionalLabel),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelAction)),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.saveAction)),
      ],
    ),
  );

  if (confirmed != true) return null;

  return (
    points: int.tryParse(pointsController.text),
    position: int.tryParse(positionController.text),
    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
  );
}
