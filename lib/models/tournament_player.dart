class TournamentPlayer {
  final String id;
  final String name;
  final String? deckArchetype;
  final bool dropped;
  final int points;
  final int wins;
  final int losses;
  final int draws;
  final int prizeDifferential;
  final List<String> opponentIds;
  final bool byeReceived;
  final bool isOrganizer;
  final String? deckId;
  final String? groupName;

  TournamentPlayer({
    required this.id,
    required this.name,
    this.deckArchetype,
    required this.dropped,
    required this.points,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.prizeDifferential,
    required this.opponentIds,
    required this.byeReceived,
    required this.isOrganizer,
    this.deckId,
    this.groupName,
  });

  factory TournamentPlayer.fromJson(Map<String, dynamic> json) {
    return TournamentPlayer(
      id: json['_id'],
      name: json['name'],
      deckArchetype: json['deckArchetype'],
      dropped: json['dropped'] ?? false,
      points: json['points'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
      prizeDifferential: json['prizeDifferential'] ?? 0,
      opponentIds: json['opponentIds'] != null ? List<String>.from(json['opponentIds']) : [],
      byeReceived: json['byeReceived'] ?? false,
      isOrganizer: json['isOrganizer'] ?? false,
      deckId: json['deckId'],
      groupName: json['groupName'],
    );
  }
}