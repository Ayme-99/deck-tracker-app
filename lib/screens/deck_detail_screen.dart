import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/match.dart';
import '../services/stats_service.dart';
import '../services/match_service.dart';
import 'register_match_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final _statsService = StatsService();
  final _matchService = MatchService();

  Map<String, dynamic>? _overview;
  List<dynamic> _matchups = [];
  List<Match> _recentMatches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _statsService.getDeckOverview(widget.deck.id),
        _statsService.getDeckMatchups(widget.deck.id),
        _matchService.getMatches(deckId: widget.deck.id, limit: 5),
      ]);

      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _matchups = results[1] as List<dynamic>;
        _recentMatches = results[2] as List<Match>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _resultColor(String result) {
    switch (result) {
      case 'win':
        return Colors.green;
      case 'loss':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _resultLabel(String result) {
    switch (result) {
      case 'win':
        return 'Victoria';
      case 'loss':
        return 'Derrota';
      default:
        return 'Empate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deck.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _loadData, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildOverviewCard(),
                      const SizedBox(height: 24),
                      _buildMatchupsSection(),
                      const SizedBox(height: 24),
                      _buildRecentMatchesSection(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final registered = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => RegisterMatchScreen(deck: widget.deck)),
          );
          if (registered == true) _loadData(); // refresca stats tras registrar
        },
      icon: const Icon(Icons.add),
      label: const Text('Partida'),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final overview = _overview!;
    final winRate = overview['winRate'] ?? 0;
    final totalMatches = overview['totalMatches'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.deck.format} · $totalMatches partidas',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn('$winRate%', 'Win rate', Colors.deepPurple),
                _statColumn('${overview['wins']}', 'Victorias', Colors.green),
                _statColumn('${overview['losses']}', 'Derrotas', Colors.red),
                _statColumn('${overview['ties']}', 'Empates', Colors.grey),
              ],
            ),
            if (totalMatches > 0) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn('${overview['totalUserPrizes']}', 'Premios cogidos', Colors.black87),
                  _statColumn('${overview['totalOpponentPrizes']}', 'Premios cedidos', Colors.black54),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildMatchupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Matchups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_matchups.isEmpty)
          const Text('Todavía no hay partidas registradas', style: TextStyle(color: Colors.grey))
        else
          ..._matchups.map((m) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(m['opponentDeck']),
                  subtitle: Text('${m['wins']}V - ${m['losses']}D - ${m['ties']}E'),
                  trailing: Text(
                    '${m['winRate']}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildRecentMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Partidas recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_recentMatches.isEmpty)
          const Text('Todavía no hay partidas registradas', style: TextStyle(color: Colors.grey))
        else
          ..._recentMatches.map((match) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _resultColor(match.result).withOpacity(0.15),
                    child: Icon(
                      match.result == 'win'
                          ? Icons.check
                          : match.result == 'loss'
                              ? Icons.close
                              : Icons.remove,
                      color: _resultColor(match.result),
                    ),
                  ),
                  title: Text('vs ${match.opponentDeck}'),
                  subtitle: Text(
                    '${_resultLabel(match.result)} · ${match.userPrizes}-${match.opponentPrizes}',
                  ),
                  trailing: Text(
                    '${match.playedAt.day}/${match.playedAt.month}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              )),
      ],
    );
  }
}