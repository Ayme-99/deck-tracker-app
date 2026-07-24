import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/stats_service.dart';
import '../../services/deck_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../widgets/sprite_avatar_group.dart';
import '../../widgets/sprite_picker.dart';
import '../../widgets/winrate_chart.dart';
import '../decks/deck_detail_screen.dart';
import '../../widgets/slow_loading_indicator.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  final _statsService = StatsService();
  final _deckService = DeckService();
  final _archetypeService = OpponentArchetypeService();
  late final TabController _tabController;

  Map<String, dynamic>? _overview;
  List<dynamic> _ranking = [];
  List<dynamic> _opponentMatchups = [];
  List<dynamic> _timeline = [];
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
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        _statsService.getOpponentMatchups(),
        _statsService.getGlobalTimeline(),
      ]);

      // Si el widget ya no existe (p. ej. logout durante la carga), descartar el resultado
      if (!mounted) return;

      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _ranking = results[1] as List<dynamic>;
        _opponentMatchups = results[2] as List<dynamic>;
        _timeline = results[3] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _ranking = ranking;
        _isLoadingRanking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRanking = false);
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

  Future<void> _showOpponentOptions(Map<String, dynamic> matchup) async {
    final name = matchup['opponentDeck'] as String;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar rival'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: const Text('Eliminar historial de este rival'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'edit') {
      await _editOpponent(name, matchup['sprite1'] as String?, matchup['sprite2'] as String?);
    } else if (action == 'delete') {
      await _confirmDeleteOpponent(name, matchup);
    }
  }

  Future<void> _editOpponent(String name, String? sprite1, String? sprite2) async {
    final nameController = TextEditingController(text: name);
    String? editedSprite1 = sprite1;
    String? editedSprite2 = sprite2;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar rival'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: AppSizes.spacingM),
                SpritePicker(
                  sprite1: editedSprite1,
                  sprite2: editedSprite2,
                  onChanged: (sprites) => setDialogState(() {
                    editedSprite1 = sprites[0];
                    editedSprite2 = sprites[1];
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    final newName = nameController.text.trim();
    nameController.dispose();

    if (saved != true || !mounted || newName.isEmpty) return;

    try {
      await _archetypeService.update(
        name,
        newName: newName != name ? newName : null,
        sprite1: editedSprite1,
        sprite2: editedSprite2,
      );
      if (!mounted) return;
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al editar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _confirmDeleteOpponent(String name, Map<String, dynamic> matchup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mazo rival'),
        content: Text(
          '¿Seguro que quieres eliminar "$name"? Se eliminarán también sus '
          '${matchup['totalMatches']} partidas registradas y dejarán de contar en tus '
          'estadísticas. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _archetypeService.delete(name);
      if (!mounted) return;
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
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
      return const SlowLoadingIndicator();
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spacingM, AppSizes.spacingM, AppSizes.spacingM, 0,
          ),
          child: _buildOverviewCard(overview, totalMatches),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis mazos'),
            Tab(text: 'Rivales'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyDecksTab(),
              _buildRivalsTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// Resumen global (issue #111: se mantiene visible sobre las dos pestañas,
  /// ya que no es específico ni de "mis mazos" ni de "rivales").
  Widget _buildOverviewCard(Map<String, dynamic> overview, dynamic totalMatches) {
    return Card(
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
    );
  }

  /// Pestaña "Mis mazos" (issue #111): ranking propio, con sus controles de
  /// orden y mínimo de partidas. Antes vivía apilada sobre "Contra cada rival"
  /// en el mismo ListView.
  Widget _buildMyDecksTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        children: [
          WinrateChart(timeline: _timeline, title: 'Evolución del win-rate general'),
          if (_timeline.length >= 2) const SizedBox(height: AppSizes.spacingL),
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

  /// Pestaña "Rivales" (issue #111): historial cruzado contra cada arquetipo
  /// rival, independientemente de con qué mazo propio se jugó. Antes vivía
  /// apilada bajo "Ranking de mazos" en el mismo ListView.
  Widget _buildRivalsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        children: [
          Text(
            'Cruzando todos tus mazos, sin importar con cuál jugaste',
            style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS),
          ),
          const SizedBox(height: AppSizes.spacingM),
          if (_opponentMatchups.isEmpty)
            const Text(
              'Registra partidas para ver tu historial contra cada rival',
              style: TextStyle(color: AppColors.muted),
            )
          else
            ..._opponentMatchups.map((matchup) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onLongPress: () => _showOpponentOptions(matchup as Map<String, dynamic>),
                  leading: SpriteAvatarGroup(
                    sprite1: matchup['sprite1'],
                    sprite2: matchup['sprite2'],
                    size: AppSizes.iconNormal,
                  ),
                  title: Text(
                    matchup['opponentDeck'] ?? 'Desconocido',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${matchup['totalMatches']} partidas · ${matchup['wins']}V-${matchup['losses']}D-${matchup['ties']}E',
                  ),
                  trailing: Text(
                    '${matchup['winRate']}%',
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