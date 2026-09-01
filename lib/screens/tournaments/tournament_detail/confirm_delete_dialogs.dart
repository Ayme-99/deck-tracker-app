import 'package:flutter/material.dart';

/// Dialogos de confirmacion de borrado (issue #256: extraidos de
/// tournament_detail_screen.dart). Devuelven true solo si se confirma.
Future<bool> confirmDeleteMatch(BuildContext context, {required String opponentDeck}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar partida'),
      content: Text('¿Eliminar la partida contra "$opponentDeck"?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<bool> confirmDeleteTournament(BuildContext context, {required String name}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Eliminar torneo'),
      content: Text(
        '¿Eliminar "$name"? Las partidas ya registradas no se borran, '
        'quedan sueltas fuera del torneo.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    ),
  );
  return confirmed == true;
}
