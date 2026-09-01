/// Invitacion a un torneo hosted, recibida de un amigo (issue #242).
class TournamentInvite {
  final String id;
  final String tournamentId;
  final String? tournamentName;
  final String role;
  final String status;

  TournamentInvite({
    required this.id,
    required this.tournamentId,
    this.tournamentName,
    required this.role,
    required this.status,
  });

  factory TournamentInvite.fromJson(Map<String, dynamic> json) {
    final tournament = json['tournamentId'];
    final isPopulated = tournament is Map<String, dynamic>;
    return TournamentInvite(
      id: json['_id'] as String,
      tournamentId: isPopulated ? tournament['_id'] as String : tournament as String,
      tournamentName: isPopulated ? tournament['name'] as String? : null,
      role: json['role'] as String,
      status: json['status'] as String,
    );
  }
}
