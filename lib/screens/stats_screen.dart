import 'package:flutter/material.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _statsService = StatsService();

  Map<String, dynamic>? _overview;
  List<dynamic> _ranking = [];
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
        _statsService.getGlobalOverview(),
        _statsService.getDeckRanking(),
      ]);

      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _ranking = results[1] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
      );
    }

    final overview = _overview!;
    final totalMatches = overview['totalMatches'] ?? 0;

    if (totalMatches == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Registra partidas para ver tus estadísticas globales',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalMatches partidas totales',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn('${overview['winRate']}%', 'Win rate', Colors.deepPurple),
                      _statColumn('${overview['wins']}', 'Victorias', Colors.green),
                      _statColumn('${overview['losses']}', 'Derrotas', Colors.red),
                      _statColumn('${overview['ties']}', 'Empates', Colors.grey),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn('${overview['totalUserPrizes']}', 'Premios cogidos', Colors.black87),
                      _statColumn('${overview['totalOpponentPrizes']}', 'Premios cedidos', Colors.black54),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Ranking de mazos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Mínimo 3 partidas jugadas',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_ranking.isEmpty)
            const Text(
              'Ningún mazo alcanza aún el mínimo de partidas',
              style: TextStyle(color: Colors.grey),
            )
          else
            ..._ranking.asMap().entries.map((entry) {
              final index = entry.key;
              final deck = entry.value;
              final medalColors = [Colors.amber, Colors.grey, Colors.brown];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index < 3
                        ? medalColors[index].withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: index < 3 ? medalColors[index] : Colors.grey[700],
                      ),
                    ),
                  ),
                  title: Text(deck['deckName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${deck['totalMatches']} partidas · ${deck['wins']}V-${deck['losses']}D-${deck['ties']}E'),
                  trailing: Text(
                    '${deck['winRate']}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}