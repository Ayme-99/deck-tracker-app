import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Dialogo para añadir un snapshot manual de posicion/puntos (issue #256:
/// extraido de tournament_detail_screen.dart). Solo tiene sentido en
/// torneos de tipo 'league': ahi no hay forma de derivar la clasificacion
/// a partir de las partidas propias, asi que el usuario la introduce a
/// mano cuando quiera. Devuelve null si se cancela.
Future<({int? points, int? position, String? notes})?> showAddStandingSnapshotDialog(BuildContext context) async {
  final pointsController = TextEditingController();
  final positionController = TextEditingController();
  final notesController = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Añadir posición'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Puntos'),
          ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: positionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Posición en la tabla'),
          ),
          const SizedBox(height: AppSizes.spacingM),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(labelText: 'Notas (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Guardar')),
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
