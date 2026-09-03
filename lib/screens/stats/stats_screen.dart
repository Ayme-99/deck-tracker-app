import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/stats_service.dart';
import '../../services/deck_service.dart';
import '../../widgets/opponent_options_sheet.dart';
import '../../widgets/sprite_avatar_group.dart';
import '../../widgets/winrate_chart.dart';
import '../decks/deck_detail_screen.dart';
import '../../widgets/deck_shuffle_indicator.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../../l10n/app_localizations.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  final _statsService = StatsService();
  final _deckService = DeckService();
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

  // Issue #199: filtro por nombre en la pestaña Rivales, mismo patron que
  // ya usa deck_list_screen.dart para mazos.
  final _rivalSearchController = TextEditingController();
  String _rivalSearchQuery = '';

  // Issue #196: alineado con las opciones de DeckListScreen (Nombre, Más
  // victorias) para que ambos menus de ordenar ofrezcan el mismo conjunto.
  Map<String, String> _sortByLabels(AppLocalizations l10n) => {
    'winRate': l10n.sortByOption,
    'totalMatches': l10n.sortByMatches,
    'wins': l10n.sortByMostWins,
    'deckName': l10n.sortByName,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _rivalSearchController.addListener(() {
      setState(() => _rivalSearchQuery = _rivalSearchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rivalSearchController.dispose();
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
        SnackBar(content: Text(AppLocalizations.of(context).filterError(e.toString().replaceFirst('Exception: ', '')))),
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

      // rootNavigator: true (issue #238): esta pantalla vive dentro de la
      // rama /stats del StatefulShellRoute, con su propio Navigator anidado
      // -- sin esto, DeckDetailScreen quedaria empujado dentro del Scaffold
      // de HomeScreen en vez de a pantalla completa (mismo bug que en
      // DeckListScreen, ver 482e466).
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
      );

      // Al volver, refresca por si se registraron partidas nuevas desde el detalle
      _reloadRanking();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).openDeckError(e.toString().replaceFirst('Exception: ', '')))),
      );
    } finally {
      if (mounted) setState(() => _navigatingDeckId = null);
    }
  }

  Future<void> _showOpponentOptions(Map<String, dynamic> matchup) async {
    await showOpponentOptionsSheet(
      context,
      name: matchup['opponentDeck'] as String,
      sprite1: matchup['sprite1'] as String?,
      sprite2: matchup['sprite2'] as String?,
      totalMatches: matchup['totalMatches'] as int?,
      onChanged: _loadData,
    );
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

  Widget _buildRankingControls(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _sortBy,
            decoration: InputDecoration(
              labelText: l10n.sortByLabelField,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: _sortByLabels(l10n).entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: _changeSortBy,
          ),
        ),
        const SizedBox(width: AppSizes.spacingM),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.minMatchesLabel, style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS)),
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
    final l10n = AppLocalizations.of(context);
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
              Text(l10n.genericErrorLabel(_errorMessage!), textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.spacingM),
              FilledButton(onPressed: _loadData, child: Text(l10n.retryAction)),
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
          child: Text(
            l10n.noStatsYet,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    // Issue #169: la tarjeta de resumen viaja con el scroll (va dentro del
    // headerSliverBuilder, NO pinned) y solo el TabBar se queda fijo arriba
    // al hacer scroll -- antes ambos quedaban fijos, dejando poco hueco
    // visible para las listas.
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spacingM, AppSizes.spacingM, AppSizes.spacingM, 0),
          sliver: SliverToBoxAdapter(child: _buildOverviewCard(l10n, overview, totalMatches)),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedTabBarDelegate(
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.myDecksTabLabel),
                Tab(text: l10n.rivalsTabLabel),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyDecksTab(l10n),
          _buildRivalsTab(l10n),
        ],
      ),
    );
  }

  /// Resumen global (issue #111: se mantiene visible sobre las dos pestañas,
  /// ya que no es específico ni de "mis mazos" ni de "rivales").
  Widget _buildOverviewCard(AppLocalizations l10n, Map<String, dynamic> overview, dynamic totalMatches) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.totalMatchesCount(totalMatches),
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn('${overview['winRate']}%', l10n.winRateLabel, AppColors.primaryVariant),
                _statColumn('${overview['wins']}', l10n.winsLabel, AppColors.success),
                _statColumn('${overview['losses']}', l10n.lossesLabel, AppColors.error),
                _statColumn('${overview['ties']}', l10n.tiesLabel, AppColors.muted),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn('${overview['totalUserPrizes']}', l10n.prizesTakenLabel, AppColors.surface),
                _statColumn('${overview['totalOpponentPrizes']}', l10n.prizesGivenLabel, AppColors.surface),
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
  Widget _buildMyDecksTab(AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        children: [
          WinrateChart(timeline: _timeline, title: l10n.winrateEvolutionTitle),
          if (_timeline.length >= 2) const SizedBox(height: AppSizes.spacingL),
          _buildRankingControls(l10n),
          const SizedBox(height: AppSizes.spacingM),
          if (_isLoadingRanking)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.spacingL),
                child: DeckShuffleIndicator(size: 40),
              ),
            )
          else if (_ranking.isEmpty)
            Text(
              l10n.noDeckReachesMinMatches,
              style: const TextStyle(color: AppColors.muted),
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
                  subtitle: Text(l10n.matchesCountSummary(deck['totalMatches'], deck['wins'], deck['losses'], deck['ties'])),
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
  Widget _buildRivalsTab(AppLocalizations l10n) {
    final filteredMatchups = _rivalSearchQuery.isEmpty
        ? _opponentMatchups
        : _opponentMatchups
            .where((m) => ((m as Map<String, dynamic>)['opponentDeck'] as String? ?? '')
                .toLowerCase()
                .contains(_rivalSearchQuery))
            .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        children: [
          Text(
            l10n.crossAllDecksHint,
            style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS),
          ),
          const SizedBox(height: AppSizes.spacingM),
          if (_opponentMatchups.isNotEmpty)
            TextField(
              controller: _rivalSearchController,
              decoration: InputDecoration(
                hintText: l10n.searchRivalHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _rivalSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _rivalSearchController.clear(),
                      )
                    : null,
              ),
            ),
          if (_opponentMatchups.isNotEmpty) const SizedBox(height: AppSizes.spacingM),
          if (_opponentMatchups.isEmpty)
            Text(
              l10n.noRivalHistoryYet,
              style: const TextStyle(color: AppColors.muted),
            )
          else if (filteredMatchups.isEmpty)
            Text(
              l10n.noRivalMatchesSearch(_rivalSearchQuery),
              style: const TextStyle(color: AppColors.muted),
            )
          else
            ...filteredMatchups.map((matchup) {
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
                    matchup['opponentDeck'] ?? l10n.unknownLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    l10n.matchesCountSummary(matchup['totalMatches'], matchup['wins'], matchup['losses'], matchup['ties']),
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

/// Envuelve el TabBar para poder fijarlo (pinned) dentro del
/// headerSliverBuilder de un NestedScrollView (issue #169). Da un fondo
/// solido (Material del tema) para que no se vea el contenido scrolleando
/// por debajo cuando queda pegado arriba.
class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _PinnedTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) => tabBar != oldDelegate.tabBar;
}