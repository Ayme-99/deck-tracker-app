import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Dialogos de confirmacion de borrado (issue #256: extraidos de
/// tournament_detail_screen.dart). Devuelven true solo si se confirma.
Future<bool> confirmDeleteMatch(BuildContext context, {required String opponentDeck}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteMatchAction),
      content: Text(l10n.deleteMatchConfirm(opponentDeck)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelAction)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteAction, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<bool> confirmDeleteTournament(BuildContext context, {required String name}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteTournamentAction),
      content: Text(l10n.deleteTournamentConfirm(name)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelAction)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteAction, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    ),
  );
  return confirmed == true;
}
