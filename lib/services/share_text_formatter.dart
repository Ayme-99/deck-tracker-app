import '../models/match.dart';
import '../models/tournament.dart';
import '../l10n/app_localizations.dart';

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

  static String _resultLabel(AppLocalizations l10n, String result) {
    switch (result) {
      case 'win':
        return l10n.matchResultWin;
      case 'loss':
        return l10n.matchResultLoss;
      default:
        return l10n.matchResultTie;
    }
  }

  /// [deckName] es opcional: en el contexto de un torneo no siempre hace
  /// falta repetir el nombre del propio mazo.
  static String formatMatch(AppLocalizations l10n, Match match, {String? deckName}) {
    final header = deckName != null ? '$deckName vs ${match.opponentDeck}' : 'vs ${match.opponentDeck}';
    final phaseInfo = match.phase != null
        ? ' · ${matchPhaseLabels(l10n)[match.phase] ?? match.phase}${match.round != null ? ' (${l10n.roundLabel(match.round!)})' : ''}'
        : '';

    return '$header\n'
        '${_resultLabel(l10n, match.result)} · ${match.userPrizes}-${match.opponentPrizes}$phaseInfo\n'
        '${_formatDate(match.playedAt)}';
  }

  static String formatTournamentSummary(AppLocalizations l10n, Tournament tournament, Map<String, dynamic> summary) {
    final overall = summary['overall'] as Map<String, dynamic>;
    final lines = <String>[
      tournament.name,
      tournamentStructureLabels(l10n)[tournament.structure] ?? tournament.structure ?? '',
      '${overall['wins']}V-${overall['losses']}D-${overall['ties']}E · ${overall['winRate']}% win rate',
      if (tournament.finalStanding != null && tournament.finalStanding!.isNotEmpty)
        '🏆 ${tournament.finalStanding}',
    ];
    return lines.where((l) => l.isNotEmpty).join('\n');
  }
}
