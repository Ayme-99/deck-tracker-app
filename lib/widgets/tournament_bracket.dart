import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../models/tournament_match.dart';
import '../models/tournament_player.dart';
import 'sprite_avatar_group.dart';

/// Arbol de eliminatoria directa (issue #46), combinando el estilo de
/// bracketmaker.app (columnas por fase, conectores en angulo recto) y de
/// la app "Winner" (tema oscuro, sprite por jugador, "Sin resultado" en
/// vez de badge "vs"). Ver capturas de referencia en la conversacion.
///
/// Layout: cada fase es una columna; los centros verticales de cada
/// partido se calculan de abajo a arriba (los de la 1a fase se reparten
/// uniformemente, y cada fase siguiente centra su partido entre los dos
/// de los que depende), sin necesidad de medir RenderBox tras el layout.
class TournamentBracket extends StatelessWidget {
  final List<String> phaseOrder;
  final Map<String, List<TournamentMatch>> matchesByPhase;
  final Map<String, TournamentPlayer> playersById;
  final void Function(TournamentMatch match) onMatchTap;

  static const double cardWidth = 210;
  static const double cardHeight = 64;
  static const double rowHeight = cardHeight / 2;
  static const double leafGap = 14;
  static const double colGap = 48;

  const TournamentBracket({
    super.key,
    required this.phaseOrder,
    required this.matchesByPhase,
    required this.playersById,
    required this.onMatchTap,
  });

  TournamentPlayer? _player(String? id) => id == null ? null : playersById[id];

  @override
  Widget build(BuildContext context) {
    // Solo se pintan las fases que ya tienen partidas creadas; las fases
    // futuras del bracket no existen todavia hasta que se avanza (ver
    // advanceBracketRound en el backend).
    final phasesWithMatches = phaseOrder.where((p) => (matchesByPhase[p] ?? []).isNotEmpty).toList();
    if (phasesWithMatches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.spacingL),
        child: Center(child: Text('Todavía no hay bracket generado', style: TextStyle(color: AppColors.muted))),
      );
    }

    // Separa el partido de 3er/4º puesto (si existe) del resto del arbol principal
    TournamentMatch? thirdPlaceMatch;
    for (final m in matchesByPhase['final'] ?? []) {
      if (m.isThirdPlaceMatch) {
        thirdPlaceMatch = m;
        break;
      }
    }
    final mainMatchesByPhase = {
      for (final p in phasesWithMatches)
        p: (matchesByPhase[p] ?? []).where((m) => !m.isThirdPlaceMatch).toList(),
    };

    // Centros verticales por fase, calculados de abajo a arriba
    final centers = <String, List<double>>{};
    for (int i = 0; i < phasesWithMatches.length; i++) {
      final phase = phasesWithMatches[i];
      final matches = mainMatchesByPhase[phase]!;
      if (i == 0) {
        centers[phase] = List.generate(
          matches.length,
          (idx) => idx * (cardHeight + leafGap) + cardHeight / 2,
        );
      } else {
        final prevPhase = phasesWithMatches[i - 1];
        final prevCenters = centers[prevPhase]!;
        centers[phase] = List.generate(matches.length, (idx) {
          final c1 = prevCenters.length > idx * 2 ? prevCenters[idx * 2] : 0.0;
          final c2 = prevCenters.length > idx * 2 + 1 ? prevCenters[idx * 2 + 1] : c1;
          return (c1 + c2) / 2;
        });
      }
    }

    final totalHeight = centers[phasesWithMatches.first]!.isEmpty
        ? cardHeight
        : centers[phasesWithMatches.first]!.last + cardHeight / 2 + leafGap;
    final totalWidth = phasesWithMatches.length * cardWidth + (phasesWithMatches.length - 1) * colGap;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(AppSizes.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(totalWidth, totalHeight),
                  painter: _BracketConnectorPainter(
                    phasesWithMatches: phasesWithMatches,
                    centers: centers,
                    matchesByPhase: mainMatchesByPhase,
                  ),
                ),
                for (int i = 0; i < phasesWithMatches.length; i++)
                  for (int j = 0; j < mainMatchesByPhase[phasesWithMatches[i]]!.length; j++)
                    Positioned(
                      left: i * (cardWidth + colGap),
                      top: centers[phasesWithMatches[i]]![j] - cardHeight / 2,
                      child: _BracketMatchCard(
                        width: cardWidth,
                        height: cardHeight,
                        match: mainMatchesByPhase[phasesWithMatches[i]]![j],
                        player1: _player(mainMatchesByPhase[phasesWithMatches[i]]![j].player1Id),
                        player2: _player(mainMatchesByPhase[phasesWithMatches[i]]![j].player2Id),
                        onTap: () => onMatchTap(mainMatchesByPhase[phasesWithMatches[i]]![j]),
                      ),
                    ),
                // Etiquetas de fase arriba de cada columna
                for (int i = 0; i < phasesWithMatches.length; i++)
                  Positioned(
                    left: i * (cardWidth + colGap),
                    top: 0,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        kTournamentMatchPhaseLabels[phasesWithMatches[i]] ?? phasesWithMatches[i],
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: AppSizes.textXS),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (thirdPlaceMatch != null) ...[
            const SizedBox(height: AppSizes.spacingL),
            const Text('3er y 4º puesto', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: AppSizes.textXS)),
            const SizedBox(height: AppSizes.spacingXS),
            _BracketMatchCard(
              width: cardWidth,
              height: cardHeight,
              match: thirdPlaceMatch,
              player1: _player(thirdPlaceMatch.player1Id),
              player2: _player(thirdPlaceMatch.player2Id),
              onTap: () => onMatchTap(thirdPlaceMatch!),
            ),
          ],
        ],
      ),
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  final double width;
  final double height;
  final TournamentMatch match;
  final TournamentPlayer? player1;
  final TournamentPlayer? player2;
  final VoidCallback onTap;

  const _BracketMatchCard({
    required this.width,
    required this.height,
    required this.match,
    required this.player1,
    required this.player2,
    required this.onTap,
  });

  Widget _row(TournamentPlayer? player, {required bool isBye}) {
    return SizedBox(
      height: height / 2,
      child: Row(
        children: [
          SpriteAvatarGroup(
            sprite1: null, // el arquetipo del jugador no trae sprite propio resuelto aqui; se añade en #47 si aporta
            size: AppSizes.iconSmall,
            centerAlign: true,
          ),
          const SizedBox(width: AppSizes.spacingXS),
          Expanded(
            child: Text(
              isBye ? 'BYE' : (player?.name ?? '?'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: isBye ? AppColors.muted : null),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultLabel = match.status == 'completed'
        ? (match.isDraw
            ? 'Empate'
            : '${match.player1Prizes ?? '-'} - ${match.player2Prizes ?? '-'}')
        : 'Sin resultado';

    return InkWell(
      onTap: onTap,
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
                  _row(player1, isBye: false),
                  const Divider(height: 1),
                  _row(player2, isBye: match.isBye),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.spacingXS),
            Text(
              resultLabel,
              style: TextStyle(
                color: match.status == 'completed' ? null : AppColors.muted,
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

class _BracketConnectorPainter extends CustomPainter {
  final List<String> phasesWithMatches;
  final Map<String, List<double>> centers;
  final Map<String, List<TournamentMatch>> matchesByPhase;

  _BracketConnectorPainter({
    required this.phasesWithMatches,
    required this.centers,
    required this.matchesByPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < phasesWithMatches.length - 1; i++) {
      final phase = phasesWithMatches[i];
      final nextPhaseName = phasesWithMatches[i + 1];
      final phaseCenters = centers[phase]!;
      final nextCenters = centers[nextPhaseName]!;

      final x1 = i * (TournamentBracket.cardWidth + TournamentBracket.colGap) + TournamentBracket.cardWidth;
      final xMid = x1 + TournamentBracket.colGap / 2;
      final x2 = (i + 1) * (TournamentBracket.cardWidth + TournamentBracket.colGap);

      for (int j = 0; j < nextCenters.length; j++) {
        final yChild0 = phaseCenters.length > j * 2 ? phaseCenters[j * 2] : null;
        final yChild1 = phaseCenters.length > j * 2 + 1 ? phaseCenters[j * 2 + 1] : null;
        final yParent = nextCenters[j];

        if (yChild0 != null) canvas.drawLine(Offset(x1, yChild0), Offset(xMid, yChild0), paint);
        if (yChild1 != null) canvas.drawLine(Offset(x1, yChild1), Offset(xMid, yChild1), paint);
        if (yChild0 != null && yChild1 != null) {
          canvas.drawLine(Offset(xMid, yChild0), Offset(xMid, yChild1), paint);
        }
        canvas.drawLine(Offset(xMid, yParent), Offset(x2, yParent), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter oldDelegate) => true;
}