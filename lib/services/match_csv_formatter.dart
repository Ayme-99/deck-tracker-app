import '../models/match.dart';

/// Genera el CSV del historial de partidas de un mazo o torneo (issue #162),
/// para analizar en Excel/Sheets con mas detalle del que cabe en el resumen
/// de texto plano de compartir (issue #130). Logica pura (sin depender del
/// plugin de compartir), para poder testearla sin el share sheet nativo.
class MatchCsvFormatter {
  MatchCsvFormatter._();

  static const _header = ['Fecha', 'Rival', 'Resultado', 'Mis premios', 'Premios rival', 'Fase', 'Ronda', 'Notas'];

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

  static String format(List<Match> matches) {
    final buffer = StringBuffer()
      ..writeln(_row(_header));

    for (final match in matches) {
      buffer.writeln(_row([
        _formatDate(match.playedAt),
        match.opponentDeck,
        _resultLabel(match.result),
        '${match.userPrizes}',
        '${match.opponentPrizes}',
        match.phase != null ? (kMatchPhaseLabels[match.phase] ?? match.phase!) : '',
        match.round?.toString() ?? '',
        match.notes ?? '',
      ]));
    }

    return buffer.toString();
  }
}
