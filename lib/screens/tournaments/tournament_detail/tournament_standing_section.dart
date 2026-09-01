import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/tournament.dart';
import '../../../l10n/app_localizations.dart';

/// Historial manual de posición/puntos (solo aplica a torneos 'league',
/// issue #115: extraida de tournament_detail_screen.dart).
class TournamentStandingSection extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onAddSnapshot;

  const TournamentStandingSection({
    super.key,
    required this.tournament,
    required this.onAddSnapshot,
  });

  String _formatSnapshotDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshots = [...tournament.standingSnapshots]..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.standingsSectionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM)),
                TextButton.icon(
                  onPressed: onAddSnapshot,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAction),
                ),
              ],
            ),
            if (snapshots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
                child: Text(
                  l10n.trackStandingHint,
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...snapshots.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXS),
                  child: Row(
                    children: [
                      SizedBox(
                        width: AppSizes.columnWidthM,
                        child: Text(
                          _formatSnapshotDate(s.date),
                          style: const TextStyle(color: AppColors.muted, fontSize: AppSizes.textXS),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          [
                            if (s.position != null) l10n.positionOrdinal(s.position!),
                            if (s.points != null) l10n.pointsAbbreviation(s.points!),
                            if (s.notes != null && s.notes!.isNotEmpty) s.notes!,
                          ].join(' · '),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
