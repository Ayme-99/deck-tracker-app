import 'dart:async';
import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../services/deck_cache_service.dart';
import '../../services/deck_service.dart';
import '../../services/pending_delete_controller.dart';
import '../../services/stats_service.dart';
import '../../services/tab_refresh_signals.dart';
import 'deck_detail_screen.dart';
import 'deck_list_tile.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../../l10n/app_localizations.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  final _deckService = DeckService();
  final _statsService = StatsService();
  final _cacheService = DeckCacheService();
  final _searchController = TextEditingController();

  List<Deck> _decks = [];
  Map<String, Map<String, dynamic>> _overviews = {};
  bool _isLoading = true;
  String? _errorMessage;
  // Issue #133: true si lo que se ve en pantalla viene del cache local
  // (carga inicial antes de que responda la red, o la red fallo tras haber
  // podido mostrar algo). Nunca se activa si la ultima carga de red tuvo
  // exito.
  bool _isShowingCachedData = false;
  String _searchQuery = '';
  // 'activity' (por defecto, ultima actividad primero), 'name' (A-Z) o 'wins' (mas victorias primero)
  String _sortBy = 'activity';

  late final _pendingDelete = PendingDeleteController<Deck>(
    onDelete: (deck) async {
      try {
        await _deckService.deleteDeck(deck.id);
      } catch (e) {
        // Si el borrado real falla (ej. sin red), se repone el mazo en la
        // lista -- el usuario ya dio por hecho que se habia ido.
        if (!mounted) return;
        setState(() => _decks = [..._decks, deck]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).deckDeleteError(deck.name, e.toString().replaceFirst('Exception: ', '')))),
        );
      }
    },
    onRemoveLocally: (deck) => setState(() => _decks = _decks.where((d) => d.id != deck.id).toList()),
    onRestoreLocally: (deck) => setState(() => _decks = [..._decks, deck]),
    buildMessage: (deck) => AppLocalizations.of(context).deckDeletedSnackbar(deck.name),
  );

  @override
  void initState() {
    super.initState();
    _loadDecks();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    // Ver tab_refresh_signals.dart: goBranch(index, initialLocation: true)
    // no basta para forzar la recarga tras crear un mazo desde HomeScreen,
    // ya que esta pantalla vive en su propia rama del StatefulShellRoute.
    deckListRefreshSignal.addListener(_loadDecks);
  }

  @override
  void dispose() {
    deckListRefreshSignal.removeListener(_loadDecks);
    _pendingDelete.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    // Issue #133: si es la primera carga (aun no hay nada en pantalla),
    // intenta mostrar el cache local al instante mientras la red responde,
    // en vez de dejar solo el spinner. Si ya habia datos (ej. pull-to-refresh),
    // se dejan como estan hasta que la red responda.
    if (_decks.isEmpty) {
      final cached = await _cacheService.load();
      if (cached != null && mounted) {
        setState(() {
          _decks = cached.decks;
          _overviews = cached.overviews;
          _isLoading = false;
          _isShowingCachedData = true;
        });
      } else {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    }

    try {
      final decks = await _deckService.getDecks();

      // Si el widget ya no existe (p. ej. logout durante la carga), no lanzar más peticiones
      if (!mounted) return;

      // Trae el overview completo de cada mazo en paralelo (partidas, V-D-E)
      final overviewsList = await Future.wait(
        decks.map((deck) => _statsService.getDeckOverview(deck.id)),
      );

      if (!mounted) return;

      final overviewsMap = <String, Map<String, dynamic>>{};
      for (var i = 0; i < decks.length; i++) {
        overviewsMap[decks[i].id] = overviewsList[i];
      }

      // Filtra cualquier mazo con un borrado pendiente (SnackBar de
      // deshacer todavia abierto), para que un reload de fondo no lo haga
      // "reaparecer" antes de que se resuelva.
      final pendingIds = _pendingDelete.pendingItems.map((d) => d.id).toSet();
      final finalDecks = decks.where((d) => !pendingIds.contains(d.id)).toList();

      setState(() {
        _decks = finalDecks;
        _overviews = overviewsMap;
        _isLoading = false;
        _isShowingCachedData = false;
        _errorMessage = null;
      });

      unawaited(_cacheService.save(finalDecks, overviewsMap));
    } catch (e) {
      if (!mounted) return;

      // Si ya hay algo en pantalla (cache local o una carga anterior), no lo
      // tapamos con la pantalla de error: se deja visible con el aviso de
      // "sin conexion" (issue #133).
      if (_decks.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _isShowingCachedData = true;
        });
      } else {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _sortLabel(AppLocalizations l10n) {
    switch (_sortBy) {
      case 'name':
        return l10n.sortByName;
      case 'wins':
        return l10n.sortByMostWins;
      case 'winRate':
        return l10n.sortByWinRate;
      default:
        return l10n.sortByRecentActivity;
    }
  }

  // Issue #196: win rate de un mazo a partir de su overview ya cargado
  // (wins/losses/ties), 0 si aun no tiene overview u partidas.
  double _winRateOf(Deck deck) {
    final overview = _overviews[deck.id];
    if (overview == null) return 0;
    final wins = (overview['wins'] ?? 0) as num;
    final losses = (overview['losses'] ?? 0) as num;
    final ties = (overview['ties'] ?? 0) as num;
    final total = wins + losses + ties;
    return total == 0 ? 0 : wins / total;
  }

  List<Deck> get _filteredDecks {
    final base = _searchQuery.isEmpty
        ? _decks
        : _decks.where((d) => d.name.toLowerCase().contains(_searchQuery)).toList();

    final sorted = [...base];
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'wins':
        sorted.sort((a, b) {
          final winsA = _overviews[a.id]?['wins'] ?? 0;
          final winsB = _overviews[b.id]?['wins'] ?? 0;
          return (winsB as num).compareTo(winsA as num);
        });
        break;
      case 'winRate':
        sorted.sort((a, b) => _winRateOf(b).compareTo(_winRateOf(a)));
        break;
      default:
        // Ultima actividad (updatedAt, o createdAt si no existe), mas reciente primero
        sorted.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    }
    return sorted;
  }

  Future<void> _showDeckOptions(Deck deck) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editDeckAction),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l10n.duplicateDeckAction),
              onTap: () => Navigator.of(context).pop('duplicate'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text(l10n.deleteDeckAction),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    // rootNavigator: true (issue #238): esta pantalla vive dentro de la
    // rama /decks del StatefulShellRoute, con su propio Navigator anidado
    // -- mismo bug que el corregido en 482e466.
    if (action == 'edit') {
      final updated = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(builder: (_) => DeckFormScreen(deck: deck)),
      );
      if (updated == true) _loadDecks();
    } else if (action == 'duplicate') {
      final created = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(builder: (_) => DeckFormScreen(duplicateFrom: deck)),
      );
      if (created == true) _loadDecks();
    } else if (action == 'delete') {
      _confirmDeleteDeck(deck);
    }
  }

  Future<void> _confirmDeleteDeck(Deck deck) async {
    final l10n = AppLocalizations.of(context);
    final overview = _overviews[deck.id];
    final totalMatches =
        (overview?['wins'] ?? 0) + (overview?['losses'] ?? 0) + (overview?['ties'] ?? 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDeckAction),
        content: Text(
          totalMatches > 0
              ? l10n.deleteDeckConfirmWithMatches(deck.name, totalMatches)
              : l10n.deleteDeckConfirmSimple(deck.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAction, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _pendingDelete.requestDelete(context, deck);
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacingM,
        AppSizes.spacingM,
        AppSizes.spacingM,
        AppSizes.spacingS,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.deckSearchHint,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSortMenu(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacingM,
        0,
        AppSizes.spacingM,
        AppSizes.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'activity', child: Text(l10n.sortByRecentActivity)),
              PopupMenuItem(value: 'name', child: Text(l10n.sortByName)),
              PopupMenuItem(value: 'wins', child: Text(l10n.sortByMostWins)),
              PopupMenuItem(value: 'winRate', child: Text(l10n.sortByWinRate)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: AppSizes.iconSmall, color: AppColors.muted),
                const SizedBox(width: AppSizes.spacingXS),
                Text(
                  l10n.sortByLabel(_sortLabel(l10n)),
                  style: const TextStyle(color: AppColors.muted, fontSize: AppSizes.textS),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aviso de que lo que se ve viene del cache local (issue #133): carga
  /// inicial antes de que responda la red, o red caida tras haber podido
  /// mostrar algo previamente.
  Widget _buildOfflineBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      color: AppColors.muted.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingM,
        vertical: AppSizes.spacingS,
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: AppSizes.iconSmall, color: AppColors.muted),
          const SizedBox(width: AppSizes.spacingXS),
          Expanded(
            child: Text(
              l10n.offlineShowingSavedData,
              style: const TextStyle(color: AppColors.muted, fontSize: AppSizes.textS),
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vacio (sin mazos todavia), con boton directo a crear el primero.
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style_outlined, size: AppSizes.iconHuge, color: AppColors.muted),
            const SizedBox(height: AppSizes.spacingM),
            Text(
              l10n.noDecksYetTitle,
              style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              l10n.noDecksYetSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
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
              Text(l10n.deckLoadError(_errorMessage!), textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.spacingM),
              FilledButton.icon(
                onPressed: () async {
                  final created = await Navigator.of(context, rootNavigator: true).push<bool>(
                    MaterialPageRoute(builder: (_) => const DeckFormScreen()),
                  );
                  if (created == true) _loadDecks();
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.createDeckAction),
              ),
            ],
          ),
        ),
      );
    }

    if (_decks.isEmpty) {
      return _buildEmptyState(l10n);
    }

    final filteredDecks = _filteredDecks;

    return Column(
      children: [
        if (_isShowingCachedData) _buildOfflineBanner(l10n),
        _buildSearchBar(l10n),
        _buildSortMenu(l10n),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDecks,
            child: filteredDecks.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.spacingXL),
                        child: Center(
                          child: Text(
                            l10n.noDeckMatchesSearch(_searchQuery),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.spacingM,
                      0,
                      AppSizes.spacingM,
                      AppSizes.fabBottomPadding,
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: AppSizes.spacingM,
                      crossAxisSpacing: AppSizes.spacingM,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredDecks.length,
                    itemBuilder: (context, index) {
                      final deck = filteredDecks[index];
                      final overview = _overviews[deck.id];

                      return DeckListTile(
                        deck: deck,
                        wins: overview?['wins'] ?? 0,
                        losses: overview?['losses'] ?? 0,
                        ties: overview?['ties'] ?? 0,
                        onTap: () async {
                          final result = await Navigator.of(context, rootNavigator: true).push<Object?>(
                            MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
                          );
                          // 'deleted': el mazo se borro desde su propio detalle
                          // (ver DeckDetailScreen._confirmDelete) -- se registra
                          // aqui el borrado pendiente con deshacer, en vez de
                          // recargar (que lo traeria de vuelta del servidor).
                          if (!context.mounted) return;
                          if (result == 'deleted') {
                            _pendingDelete.requestDelete(context, deck);
                          } else {
                            _loadDecks();
                          }
                        },
                        onLongPress: () => _showDeckOptions(deck),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}