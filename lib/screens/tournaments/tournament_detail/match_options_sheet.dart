import 'package:flutter/material.dart';

/// Bottom sheet de opciones de una partida (issue #256: extraido de
/// tournament_detail_screen.dart). Devuelve 'edit'/'share'/'delete', o null
/// si se cierra sin elegir nada.
Future<String?> showMatchOptionsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar partida'),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Compartir partida'),
            onTap: () => Navigator.of(context).pop('share'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: const Text('Eliminar partida'),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    ),
  );
}
