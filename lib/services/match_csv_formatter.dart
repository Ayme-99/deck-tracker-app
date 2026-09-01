import '../models/match.dart';
import '../l10n/app_localizations.dart';

/// Genera el CSV del historial de partidas de un mazo o torneo (issue #162),
/// para analizar en Excel/Sheets con mas detalle del que cabe en el resumen
/// de texto plano de compartir (issue #130). Logica pura (sin depender del
/// plugin de compartir), para poder testearla sin el share sheet nativo.
class MatchCsvFormatter {
  MatchCsvFormatter._();

  static List<String> _header(AppLocalizations l10n) => [
    l10n.csvHeaderDate,
    l10n.csvHeaderOpponent,
    l10n.csvHeaderResult,
    l10n.csvHeaderMyPrizes,
    l10n.csvHeaderOpponentPrizes,
    l10n.csvHeaderPhase,
    l10n.csvHeaderRound,
    l10n.csvHeaderNotes,
  ];

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

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Escapa un campo segun RFC 4180: si contiene comas, comillas o saltos de
  /// linea, va entre comillas dobles (duplicando las comillas internas).
  static String _escape(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _row(List<String> fields) => fields.map(_escape).join(',');

  static String format(AppLocalizations l10n, List<Match> matches) {
    final buffer = StringBuffer()
      ..writeln(_row(_header(l10n)));

    for (final match in matches) {
      buffer.writeln(_row([
        _formatDate(match.playedAt),
        match.opponentDeck,
        _resultLabel(l10n, match.result),
        '${match.userPrizes}',
        '${match.opponentPrizes}',
        match.phase != null ? (matchPhaseLabels(l10n)[match.phase] ?? match.phase!) : '',
        match.round?.toString() ?? '',
        match.notes ?? '',
      ]));
    }

    return buffer.toString();
  }
}
