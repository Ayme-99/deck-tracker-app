import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/match.dart';
import '../../../models/opponent_archetype.dart';
import '../../../widgets/sprite_avatar_group.dart';
import '../../../l10n/app_localizations.dart';

/// Ultimas partidas registradas con este mazo (issue #118: promocionada
/// desde _buildRecentMatchesSection de deck_detail_screen.dart a un widget
/// de verdad).
///
/// Issue #144: en vez de mostrar siempre toda la lista recibida, empieza
/// enseñando solo 5 y permite ampliar de 5 en 5 con "Mostrar más"; una vez
/// ampliada aparece "Ocultar" para volver a colapsarla a 5.
class DeckRecentMatchesSection extends StatefulWidget {
  final List<Match> matches;
  final Map<String, OpponentArchetype> archetypesByName;
  final void Function(Match match) onMatchTap;

  const DeckRecentMatchesSection({
    super.key,
    required this.matches,
    required this.archetypesByName,
    required this.onMatchTap,
  });

  @override
  State<DeckRecentMatchesSection> createState() => _DeckRecentMatchesSectionState();
}

class _DeckRecentMatchesSectionState extends State<DeckRecentMatchesSection> {
  static const _pageSize = 5;

  int _visibleCount = _pageSize;

  Color _resultColor(String result) {
    switch (result) {
      case 'win':
        return AppColors.success;
      case 'loss':
        return AppColors.error;
      default:
        return AppColors.muted;
    }
  }

  String _resultLabel(AppLocalizations l10n, String result) {
    switch (result) {
      case 'win':
        return l10n.matchResultWin;
      case 'loss':
        return l10n.matchResultLoss;
      default:
        return l10n.matchResultTie;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final matches = widget.matches;
    final visibleMatches = matches.take(_visibleCount).toList();
    final hasMore = _visibleCount < matches.length;
    final isExpanded = _visibleCount > _pageSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.recentMatchesSectionTitle, style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.spacingSM),
        if (matches.isEmpty)
          Text(l10n.noMatchesRegisteredYet, style: const TextStyle(color: Colors.grey))
        else ...[
          ...visibleMatches.map((match) {
            final archetype = widget.archetypesByName[match.opponentDeck];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => widget.onMatchTap(match),
                minLeadingWidth: 0,
                horizontalTitleGap: AppSizes.spacingS,
                leading: archetype?.sprite1 != null
                    ? SpriteAvatarGroup(
                        sprite1: archetype!.sprite1,
                        sprite2: archetype.sprite2,
                        size: AppSizes.iconNormal,
                      )
                    : CircleAvatar(
                        backgroundColor: _resultColor(match.result).withValues(alpha: 0.15),
                        child: Icon(
                          match.result == 'win'
                              ? Icons.check
                              : match.result == 'loss'
                                  ? Icons.close
                                  : Icons.remove,
                          color: _resultColor(match.result),
                        ),
                      ),
                title: Text(l10n.matchVsOpponent(match.opponentDeck)),
                subtitle: Text(
                  l10n.matchResultAndPrizes(_resultLabel(l10n, match.result), match.userPrizes, match.opponentPrizes),
                ),
                trailing: Text(
                  '${match.playedAt.day}/${match.playedAt.month}',
                  style: TextStyle(color: AppColors.muted, fontSize: AppSizes.textXS),
                ),
              ),
            );
          }),
          if (hasMore || isExpanded)
            Row(
              children: [
                if (hasMore)
                  TextButton(
                    onPressed: () => setState(() => _visibleCount += _pageSize),
                    child: Text(l10n.showMoreAction),
                  ),
                if (isExpanded)
                  TextButton(
                    onPressed: () => setState(() => _visibleCount = _pageSize),
                    child: Text(l10n.hideAction),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
