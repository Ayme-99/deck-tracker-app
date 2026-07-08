import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/stats_service.dart';
import '../../services/deck_service.dart';
import '../../widgets/sprite_avatar_group.dart';
import '../decks/deck_detail_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _statsService = StatsService();
  final _deckService = DeckService();

  Map<String, dynamic>? _overview;
  List<dynamic> _ranking = [];
  bool _isLoading = true;
  bool _isLoadingRanking = false;
  String? _errorMessage;
  String? _navigatingDeckId;

  String _sortBy = 'winRate';
  int _minMatches = 3;

  final _sortByLabels = const {
    'winRate': 'Win rate',
    'totalMatches': 'Partidas',
    'deckName': 'Nombre',
  };

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
        _statsService.getDeckRanking(minMatches: _minMatches, sortBy: _sortBy),
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

  Future<void> _reloadRanking() async {
    setState(() => _isLoadingRanking = true);

    try {
      final ranking = await _statsService.getDeckRanking(minMatches: _minMatches, sortBy: _sortBy);
      setState(() {
        _ranking = ranking;
        _isLoadingRanking = false;
      });
    } catch (e) {
      setState(() => _isLoadingRanking = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al filtrar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  void _changeSortBy(String? value) {
    if (value == null) return;
    setState(() => _sortBy = value);
    _reloadRanking();
  }

  void _changeMinMatches(int delta) {
    final newValue = _minMatches + delta;
    if (newValue < 1) return;
    setState(() => _minMatches = newValue);
    _reloadRanking();
  }

  Future<void> _openDeckDetail(String deckId) async {
    setState(() => _navigatingDeckId = deckId);

    try {
      final deck = await _deckService.getDeckById(deckId);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
      );

      // Al volver, refresca por si se registraron partidas nuevas desde el detalle
      _reloadRanking();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el mazo: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _navigatingDeckId = null);
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

  Widget _buildRankingControls() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _sortBy,
            decoration: const InputDecoration(
              labelText: 'Ordenar por',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _sortByLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: _changeSortBy,
          ),
        ),
        const SizedBox(width: AppSizes.spacingM),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mín. partidas', style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _minMatches > 1 ? () => _changeMinMatches(-1) : null,
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(
                  width: AppSizes.badgeWidth,
                  child: Text(
                    '$_minMatches',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _changeMinMatches(1),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
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
          const SizedBox(height: AppSizes.spacingM),
          _buildRankingControls(),
          const SizedBox(height: AppSizes.spacingM),
          if (_isLoadingRanking)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.spacingL),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_ranking.isEmpty)
            const Text(
              'Ningún mazo alcanza aún el mínimo de partidas',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ..._ranking.asMap().entries.map((entry) {
              final index = entry.key;
              final deck = entry.value;
              final deckId = deck['deckId'] as String;
              final isNavigating = _navigatingDeckId == deckId;
              final medalColors = [AppColors.warning, AppColors.muted, AppColors.muted];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  enabled: _navigatingDeckId == null,
                  onTap: () => _openDeckDetail(deckId),
                  minLeadingWidth: 0,
                  horizontalTitleGap: AppSizes.spacingS,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: AppSizes.iconNormal / 2,
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
                      const SizedBox(width: AppSizes.spacingM),
                      SpriteAvatarGroup(
                        sprite1: deck['sprite1'],
                        sprite2: deck['sprite2'],
                        size: AppSizes.iconNormal,
                      ),
                    ],
                  ),
                  title: Text(deck['deckName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${deck['totalMatches']} partidas · ${deck['wins']}V-${deck['losses']}D-${deck['ties']}E'),
                  trailing: isNavigating
                      ? const SizedBox(
                          height: AppSizes.spinnerSmall,
                          width: AppSizes.spinnerSmall,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${deck['winRate']}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.muted),
                          ],
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}