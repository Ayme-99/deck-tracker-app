import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
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
          style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: AppSizes.spacingXS),
        Text(label, style: TextStyle(color: AppColors.surface.withValues(alpha: 0.7), fontSize: AppSizes.textXS)),
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
          padding: const EdgeInsets.all(AppSizes.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.spacingM),
              FilledButton(onPressed: _loadData, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final overview = _overview!;
    final totalMatches = overview['totalMatches'] ?? 0;

    if (totalMatches == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingL),
          child: const Text(
            'Registra partidas para ver tus estadísticas globales',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        children: [
          Card(
              child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalMatches partidas totales',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn('${overview['winRate']}%', 'Win rate', AppColors.primaryVariant),
                      _statColumn('${overview['wins']}', 'Victorias', AppColors.success),
                      _statColumn('${overview['losses']}', 'Derrotas', AppColors.error),
                      _statColumn('${overview['ties']}', 'Empates', AppColors.muted),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statColumn('${overview['totalUserPrizes']}', 'Premios cogidos', AppColors.surface),
                      _statColumn('${overview['totalOpponentPrizes']}', 'Premios cedidos', AppColors.surface),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingL),
          const Text('Ranking de mazos', style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            'Mínimo 3 partidas jugadas',
            style: TextStyle(color: AppColors.muted, fontSize: AppSizes.textXS),
          ),
          const SizedBox(height: AppSizes.spacingM),
          if (_ranking.isEmpty)
            const Text(
              'Ningún mazo alcanza aún el mínimo de partidas',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ..._ranking.asMap().entries.map((entry) {
              final index = entry.key;
              final deck = entry.value;
              final medalColors = [AppColors.warning, AppColors.muted, AppColors.muted];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index < 3
                      ? medalColors[index].withValues(alpha: 0.2)
                      : AppColors.muted.withValues(alpha: 0.1),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: index < 3 ? medalColors[index] : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  title: Text(deck['deckName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${deck['totalMatches']} partidas · ${deck['wins']}V-${deck['losses']}D-${deck['ties']}E'),
                  trailing: Text(
                    '${deck['winRate']}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}