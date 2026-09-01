import '../models/tournament_invite.dart';
import 'api_service.dart';

/// Cliente del backend de invitaciones a torneos hosted (server#95, issue
/// #242): enviar, listar, aceptar y rechazar.
class TournamentInviteService {
  final _api = ApiService();

  Future<void> sendInvite(String tournamentId, {required String userId, required String role}) async {
    await _api.post('/tournaments/$tournamentId/invites', {'userId': userId, 'role': role});
  }

  Future<List<TournamentInvite>> listMyInvites() async {
    final response = await _api.get('/tournament-invites');
    return (response as List).map((i) => TournamentInvite.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<void> acceptInvite(String inviteId, {required String deckId}) async {
    await _api.post('/tournament-invites/$inviteId/accept', {'deckId': deckId});
  }

  Future<void> rejectInvite(String inviteId) async {
    await _api.post('/tournament-invites/$inviteId/reject', {});
  }
}
