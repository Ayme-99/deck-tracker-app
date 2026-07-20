import 'package:flutter/material.dart';
import '../../models/tournament_match.dart';
import '../../models/tournament_player.dart';
import '../../widgets/tournament_bracket.dart';

/// Pantalla independiente del bracket (issue #84): navegable libremente
/// con pan + zoom (InteractiveViewer), como un mapa, en vez de depender
/// del scroll horizontal limitado cuando el bracket va embebido dentro
/// de la lista de TournamentRoundsScreen.
///
/// Recibe los datos ya cargados (no vuelve a pedirlos a la API) para
/// abrir al instante; si se registra un resultado desde aqui, se hace
/// via el mismo onMatchTap que ya tiene TournamentRoundsScreen, que
/// actualiza su propio estado -- al volver atras se vera ya actualizado.
class TournamentBracketScreen extends StatelessWidget {
  final List<String> phaseOrder;
  final Map<String, List<TournamentMatch>> matchesByPhase;
  final Map<String, TournamentPlayer> playersById;
  final void Function(TournamentMatch match) onMatchTap;

  const TournamentBracketScreen({
    super.key,
    required this.phaseOrder,
    required this.matchesByPhase,
    required this.playersById,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bracket')),
      body: TournamentBracket(
        interactive: true,
        phaseOrder: phaseOrder,
        matchesByPhase: matchesByPhase,
        playersById: playersById,
        onMatchTap: onMatchTap,
      ),
    );
  }
}