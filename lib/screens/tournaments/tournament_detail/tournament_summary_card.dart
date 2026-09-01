import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/match.dart';
import '../../../l10n/app_localizations.dart';

/// Resumen W-L-T global y por fase de un torneo tracked (issue #115:
/// extraida de tournament_detail_screen.dart).
class TournamentSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const TournamentSummaryCard({super.key, required this.summary});

  Widget _statColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: AppSizes.spacingXS),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overall = summary['overall'] as Map<String, dynamic>;
    final byPhase = summary['byPhase'] as List;
    final totalMatches = overall['totalMatches'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summaryWithMatchCount(totalMatches),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.spacingM),
            if (totalMatches == 0)
              Text(l10n.noMatchesRegisteredYet, style: const TextStyle(color: AppColors.muted))
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn('${overall['winRate']}%', l10n.winRateLabel, AppColors.primaryVariant),
                  _statColumn('${overall['wins']}', l10n.winsLabel, AppColors.success),
                  _statColumn('${overall['losses']}', l10n.lossesLabel, AppColors.error),
                  _statColumn('${overall['ties']}', l10n.tiesLabel, AppColors.muted),
                ],
              ),
              if (byPhase.length > 1) ...[
                const Divider(height: AppSizes.spacingXL),
                Text(
                  l10n.byPhaseLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.spacingS),
                ...byPhase.map((p) {
                  final phase = p['phase'] as String?;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXS),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(matchPhaseLabels(l10n)[phase] ?? phase ?? l10n.noPhaseLabel),
                        Text(
                          l10n.phaseResultSummary(p['wins'], p['losses'], p['ties'], p['winRate']),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textS),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
