import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/opponent_archetype.dart';
import '../../../widgets/sprite_avatar_group.dart';
import '../../../l10n/app_localizations.dart';

/// Win-rate contra cada arquetipo rival al que se ha enfrentado este mazo
/// (issue #118: promocionada desde _buildMatchupsSection de
/// deck_detail_screen.dart a un widget de verdad).
///
/// Issue #166: con muchos rivales distintos, la lista se hacia larga y
/// costaba detectar de un vistazo contra quien se gana/pierde mas. Se anade
/// una vista de mapa de calor (grid, color segun win-rate) como alternativa
/// a la lista, intercambiables con un boton en la cabecera.
class DeckMatchupsSection extends StatefulWidget {
  final List<dynamic> matchups;
  final Map<String, OpponentArchetype> archetypesByName;

  const DeckMatchupsSection({super.key, required this.matchups, required this.archetypesByName});

  @override
  State<DeckMatchupsSection> createState() => _DeckMatchupsSectionState();
}

class _DeckMatchupsSectionState extends State<DeckMatchupsSection> {
  bool _showHeatmap = true;

  /// Rojo en 0%, amarillo en 50%, verde en 100% (mismo lenguaje de color
  /// que streaks/resultados en el resto de la app).
  Color _heatColor(num winRate) {
    final t = (winRate / 100).clamp(0.0, 1.0);
    if (t < 0.5) {
      return Color.lerp(AppColors.error, AppColors.warning, t / 0.5)!;
    }
    return Color.lerp(AppColors.warning, AppColors.success, (t - 0.5) / 0.5)!;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.matchupsSectionTitle, style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
            ),
            if (widget.matchups.isNotEmpty)
              IconButton(
                icon: Icon(_showHeatmap ? Icons.view_list_outlined : Icons.grid_view_outlined),
                tooltip: _showHeatmap ? l10n.viewAsListTooltip : l10n.viewAsHeatmapTooltip,
                onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingM),
        if (widget.matchups.isEmpty)
          Text(l10n.noMatchesRegisteredYet, style: const TextStyle(color: AppColors.muted))
        else if (_showHeatmap)
          _buildHeatmap(l10n)
        else
          _buildList(l10n),
      ],
    );
  }

  Widget _buildHeatmap(AppLocalizations l10n) {
    return Wrap(
      spacing: AppSizes.spacingS,
      runSpacing: AppSizes.spacingS,
      children: widget.matchups.map((m) {
        final winRate = m['winRate'] as num;
        final archetype = widget.archetypesByName[m['opponentDeck']];
        return Tooltip(
          message: l10n.matchupTooltip(m['opponentDeck'], m['wins'], m['losses'], m['ties']),
          child: Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS, horizontal: AppSizes.spacingXS),
            decoration: BoxDecoration(
              color: _heatColor(winRate).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpriteAvatarGroup(sprite1: archetype?.sprite1, sprite2: archetype?.sprite2, size: AppSizes.iconSmall),
                const SizedBox(height: AppSizes.spacingXS),
                Text(
                  m['opponentDeck'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: AppSizes.textXS, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$winRate%',
                  style: const TextStyle(color: Colors.white, fontSize: AppSizes.textS, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    return Column(
      children: widget.matchups.map((m) {
        final archetype = widget.archetypesByName[m['opponentDeck']];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            minLeadingWidth: 0,
            horizontalTitleGap: AppSizes.spacingS,
            leading: SpriteAvatarGroup(
              sprite1: archetype?.sprite1,
              sprite2: archetype?.sprite2,
              size: AppSizes.iconNormal,
            ),
            title: Text(m['opponentDeck']),
            subtitle: Text(l10n.matchResultSummary(m['wins'], m['losses'], m['ties'])),
            trailing: Text(
              '${m['winRate']}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
