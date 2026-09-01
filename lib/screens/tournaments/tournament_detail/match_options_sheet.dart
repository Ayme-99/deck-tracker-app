import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet de opciones de una partida (issue #256: extraido de
/// tournament_detail_screen.dart). Devuelve 'edit'/'share'/'delete', o null
/// si se cierra sin elegir nada.
Future<String?> showMatchOptionsSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.editMatchAction),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l10n.shareMatchAction),
            onTap: () => Navigator.of(context).pop('share'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.deleteMatchAction),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    ),
  );
}
