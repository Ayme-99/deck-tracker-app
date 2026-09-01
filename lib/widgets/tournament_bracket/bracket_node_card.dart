import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/tournament_match.dart';
import '../../models/tournament_player.dart';
import '../sprite_avatar_group.dart';
import 'bracket_constants.dart';
import 'bracket_layout.dart';
import '../../l10n/app_localizations.dart';

class BracketNodeCard extends StatelessWidget {
  final double width;
  final double height;
  final BracketNode node;
  final TournamentPlayer? player1;
  final TournamentPlayer? player2;
  final void Function(TournamentMatch match) onSelectMatch;

  const BracketNodeCard({
    super.key,
    required this.width,
    required this.height,
    required this.node,
    required this.player1,
    required this.player2,
    required this.onSelectMatch,
  });

  Widget _row(AppLocalizations l10n, TournamentPlayer? player, {required bool isBye}) {
    return SizedBox(
      height: BracketConstants.rowHeight,
      child: Row(
        children: [
          const SpriteAvatarGroup(
            sprite1: null,
            size: AppSizes.iconSmall,
            centerAlign: true,
          ),
          const SizedBox(width: AppSizes.spacingXS),
          Expanded(
            child: Text(
              isBye ? l10n.byeLabel : (player?.name ?? l10n.unknownPlayerPlaceholder),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isBye ? AppColors.muted : null),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (!node.isTwoLegs) {
      onSelectMatch(node.legs.first);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<TournamentMatch>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: node.legs.map((leg) {
            final label = switch (leg.leg) {
              'first_leg' => l10n.legFirstLeg,
              'second_leg' => l10n.legSecondLeg,
              'sudden_death' => l10n.legSuddenDeath,
              _ => leg.leg,
            };
            final resultText = leg.status == 'completed'
                ? (leg.isDraw ? l10n.matchResultTie : '${leg.player1Prizes ?? '-'}-${leg.player2Prizes ?? '-'}')
                : l10n.noResultYet;
            return ListTile(
              title: Text(label),
              subtitle: Text(resultText),
              onTap: () => Navigator.of(context).pop(leg),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) onSelectMatch(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingS),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _row(l10n, player1, isBye: false),
                  const Divider(height: BracketConstants.dividerHeight),
                  _row(l10n, player2, isBye: node.isBye),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spacingXS),
            Text(
              node.resultLabel(l10n),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: node.hasAnyResult ? null : AppColors.muted,
                fontSize: AppSizes.textXS,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
