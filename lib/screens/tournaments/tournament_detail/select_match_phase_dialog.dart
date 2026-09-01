import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/match.dart';
import '../../../models/tournament.dart';
import '../../../l10n/app_localizations.dart';

/// Dialogo para elegir en que fase se juega una partida nueva, respetando
/// las fases validas para la structure del torneo (issue #256: extraido de
/// tournament_detail_screen.dart). Si la fase es de las que llevan ronda
/// (swiss/grupos/liga), muestra la siguiente ronda disponible (calculada
/// por el llamador via [nextRoundFor], que depende de las partidas ya
/// cargadas). Devuelve la fase elegida, o null si se cancela.
Future<String?> showSelectMatchPhaseDialog(
  BuildContext context, {
  required List<String> validPhases,
  required int Function(String phase) nextRoundFor,
}) async {
  String selectedPhase = validPhases.first;
  final l10n = AppLocalizations.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final needsRound = kRoundBasedPhases.contains(selectedPhase);
        return AlertDialog(
          title: Text(l10n.selectMatchPhaseTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedPhase,
                decoration: InputDecoration(labelText: l10n.matchPhaseLabel),
                items: validPhases
                    .map((p) => DropdownMenuItem(value: p, child: Text(matchPhaseLabels(l10n)[p] ?? p)))
                    .toList(),
                onChanged: (value) => setDialogState(() => selectedPhase = value!),
              ),
              if (needsRound) ...[
                const SizedBox(height: AppSizes.spacingM),
                Text(
                  l10n.roundLabel(nextRoundFor(selectedPhase)),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelAction)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.continueAction)),
          ],
        );
      },
    ),
  );

  return confirmed == true ? selectedPhase : null;
}
