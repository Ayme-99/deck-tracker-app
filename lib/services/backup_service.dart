import '../models/deck.dart';
import '../models/match.dart';
import '../models/tournament.dart';
import 'deck_service.dart';
import 'match_service.dart';
import 'tournament_service.dart';

/// Resumen de cuantas entidades se restauraron, para mostrar feedback al
/// usuario tras un restore (issue #165).
class BackupRestoreSummary {
  final int decks;
  final int tournaments;
  final int matches;

  BackupRestoreSummary({required this.decks, required this.tournaments, required this.matches});
}

/// Backup/restore completo de mazos + partidas + torneos tracked (issue
/// #165). Los torneos hosted quedan fuera de alcance a proposito: ya tienen
/// su propio export/import (issue #76, ver TournamentService.exportTournament/
/// importTournament) pensado para compartir un torneo entre jugadores, con
/// jugadores/rondas/bracket -- mucho mas complejo que lo que hace falta aqui
/// (una copia de seguridad personal de la cuenta).
///
/// El restore siempre CREA entidades nuevas (nunca sobreescribe lo
/// existente): restaurar el mismo backup dos veces duplica los mazos, igual
/// que "Duplicar mazo" (issue #161). Los IDs originales del JSON solo se
/// usan para remapear las referencias cruzadas (deckId/tournamentId de cada
/// partida) a los IDs nuevos que asigna el backend al crear cada cosa.
class BackupService {
  final _deckService = DeckService();
  final _matchService = MatchService();
  final _tournamentService = TournamentService();

  static const _formatVersion = 1;

  Future<Map<String, dynamic>> buildBackup() async {
    final decks = await _deckService.getDecks();

    final allTournaments = await _tournamentService.getTournaments(limit: 500);
    final trackedTournaments = allTournaments.where((t) => t.mode == 'tracked').toList();

    final matches = <Match>[];
    for (final deck in decks) {
      matches.addAll(await _matchService.getMatches(deckId: deck.id, limit: 500));
    }

    return {
      'version': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'decks': decks.map((d) => d.toJson()).toList(),
      'tournaments': trackedTournaments.map((t) => t.toJson()).toList(),
      'matches': matches.map((m) => m.toJson()).toList(),
    };
  }

  Future<BackupRestoreSummary> restoreBackup(Map<String, dynamic> data) async {
    final deckIdMap = <String, String>{};
    final tournamentIdMap = <String, String>{};

    final decksJson = ((data['decks'] as List?) ?? []).cast<Map<String, dynamic>>();
    for (final deckJson in decksJson) {
      final deck = Deck.fromJson(deckJson);
      final created = await _deckService.createDeck(
        deck.name,
        deck.cards.map((c) => c.toJson()).toList(),
        sprite1: deck.sprite1,
        sprite2: deck.sprite2,
      );
      deckIdMap[deck.id] = created.id;
    }

    final tournamentsJson = ((data['tournaments'] as List?) ?? []).cast<Map<String, dynamic>>();
    for (final tournamentJson in tournamentsJson) {
      final tournament = Tournament.fromJson(tournamentJson);
      final newDeckId = tournament.deckId != null ? deckIdMap[tournament.deckId] : null;

      final created = await _tournamentService.createTournament(
        name: tournament.name,
        mode: 'tracked',
        date: tournament.date,
        location: tournament.location,
        structure: tournament.structure,
        deckId: newDeckId,
        notes: tournament.notes,
        eliminationFormat: tournament.eliminationFormat,
        thirdPlacePlayoff: tournament.thirdPlacePlayoff,
        leagueDoubleRound: tournament.leagueDoubleRound,
      );
      tournamentIdMap[tournament.id] = created.id;

      // finalStanding/status no los acepta createTournament -- se aplican
      // en un segundo paso solo si hay algo que restaurar (no merece la
      // pena el PUT si el torneo restaurado sigue en curso y sin puesto).
      if (tournament.finalStanding != null || tournament.status == 'finished') {
        await _tournamentService.updateTournament(created.id, {
          if (tournament.finalStanding != null) 'finalStanding': tournament.finalStanding,
          'status': tournament.status,
        });
      }
    }

    final matchesJson = ((data['matches'] as List?) ?? []).cast<Map<String, dynamic>>();
    var restoredMatches = 0;
    for (final matchJson in matchesJson) {
      final match = Match.fromJson(matchJson);
      final newDeckId = deckIdMap[match.deckId];
      if (newDeckId == null) continue; // Mazo no restaurado (backup corrupto/parcial): se salta la partida.

      await _matchService.createMatch(
        deckId: newDeckId,
        opponentDeck: match.opponentDeck,
        userPrizes: match.userPrizes,
        opponentPrizes: match.opponentPrizes,
        endReason: match.endReason,
        notes: match.notes,
        result: match.result,
        tournamentId: match.tournamentId != null ? tournamentIdMap[match.tournamentId] : null,
        phase: match.phase,
        round: match.round,
      );
      restoredMatches++;
    }

    return BackupRestoreSummary(
      decks: decksJson.length,
      tournaments: tournamentsJson.length,
      matches: restoredMatches,
    );
  }
}
