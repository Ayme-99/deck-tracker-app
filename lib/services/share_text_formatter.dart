import '../models/match.dart';
import '../models/tournament.dart';

/// Formatea partidas/resumenes de torneo como texto plano listo para
/// compartir (issue #130) -- p. ej. para pegar en Discord/WhatsApp del
/// grupo de juego. Logica pura, sin depender del plugin de compartir, para
/// poder testearla sin necesitar el share sheet nativo.
class ShareTextFormatter {
  ShareTextFormatter._();

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static String _resultLabel(String result) {
    switch (result) {
      case 'win':
        return 'Victoria';
      case 'loss':
        return 'Derrota';
      default:
        return 'Empate';
    }
  }

  /// [deckName] es opcional: en el contexto de un torneo no siempre hace
  /// falta repetir el nombre del propio mazo.
  static String formatMatch(Match match, {String? deckName}) {
    final header = deckName != null ? '$deckName vs ${match.opponentDeck}' : 'vs ${match.opponentDeck}';
    final phaseInfo = match.phase != null
        ? ' · ${kMatchPhaseLabels[match.phase] ?? match.phase}${match.round != null ? ' (ronda ${match.round})' : ''}'
        : '';

    return '$header\n'
        '${_resultLabel(match.result)} · ${match.userPrizes}-${match.opponentPrizes}$phaseInfo\n'
        '${_formatDate(match.playedAt)}';
  }

  static String formatTournamentSummary(Tournament tournament, Map<String, dynamic> summary) {
    final overall = summary['overall'] as Map<String, dynamic>;
    final lines = <String>[
      tournament.name,
      kTournamentStructureLabels[tournament.structure] ?? tournament.structure ?? '',
      '${overall['wins']}V-${overall['losses']}D-${overall['ties']}E · ${overall['winRate']}% win rate',
      if (tournament.finalStanding != null && tournament.finalStanding!.isNotEmpty)
        '🏆 ${tournament.finalStanding}',
    ];
    return lines.where((l) => l.isNotEmpty).join('\n');
  }
}
