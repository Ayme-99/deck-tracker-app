import 'dart:async';
import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../services/deck_cache_service.dart';
import '../../services/deck_service.dart';
import '../../services/pending_delete_controller.dart';
import '../../services/stats_service.dart';
import 'deck_detail_screen.dart';
import 'deck_list_tile.dart';
import '../../widgets/slow_loading_indicator.dart';

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
          SnackBar(content: Text('Error al eliminar "${deck.name}": ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    },
    onRemoveLocally: (deck) => setState(() => _decks = _decks.where((d) => d.id != deck.id).toList()),
    onRestoreLocally: (deck) => setState(() => _decks = [..._decks, deck]),
    buildMessage: (deck) => 'Mazo "${deck.name}" eliminado',
  );

  @override
  void initState() {
    super.initState();
    _loadDecks();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
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

  String get _sortLabel {
    switch (_sortBy) {
      case 'name':
        return 'Nombre';
      case 'wins':
        return 'Más victorias';
      default:
        return 'Actividad reciente';
    }
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
      default:
        // Ultima actividad (updatedAt, o createdAt si no existe), mas reciente primero
        sorted.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    }
    return sorted;
  }

  Future<void> _showDeckOptions(Deck deck) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar mazo'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: const Text('Eliminar mazo'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'edit') {
      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => DeckFormScreen(deck: deck)),
      );
      if (updated == true) _loadDecks();
    } else if (action == 'delete') {
      _confirmDeleteDeck(deck);
    }
  }

  Future<void> _confirmDeleteDeck(Deck deck) async {
    final overview = _overviews[deck.id];
    final totalMatches =
        (overview?['wins'] ?? 0) + (overview?['losses'] ?? 0) + (overview?['ties'] ?? 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mazo'),
        content: Text(
          totalMatches > 0
              ? '¿Seguro que quieres eliminar "${deck.name}"? Se eliminarán también '
                  'sus $totalMatches partidas registradas y dejarán de contar en tus '
                  'estadísticas.'
              : '¿Seguro que quieres eliminar "${deck.name}"?',
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

    if (confirmed != true || !mounted) return;

    _pendingDelete.requestDelete(context, deck);
  }

  Widget _buildSearchBar() {
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
          hintText: 'Buscar mazo por nombre',
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

  Widget _buildSortMenu() {
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
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'activity', child: Text('Actividad reciente')),
              PopupMenuItem(value: 'name', child: Text('Nombre')),
              PopupMenuItem(value: 'wins', child: Text('Más victorias')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: AppSizes.iconSmall, color: AppColors.muted),
                const SizedBox(width: AppSizes.spacingXS),
                Text(
                  'Ordenar: $_sortLabel',
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
  Widget _buildOfflineBanner() {
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
          const Expanded(
            child: Text(
              'Sin conexión · mostrando datos guardados',
              style: TextStyle(color: AppColors.muted, fontSize: AppSizes.textS),
            ),
          ),
        ],
      ),
    );
  }

  /// Estado vacio (sin mazos todavia), con boton directo a crear el primero.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style_outlined, size: AppSizes.iconHuge, color: AppColors.muted),
            const SizedBox(height: AppSizes.spacingM),
            const Text(
              'Todavía no tienes mazos',
              style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacingS),
            const Text(
              'Crea tu primer mazo para empezar a registrar partidas',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
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
              Text('Error al cargar mazos: $_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.spacingM),
              FilledButton.icon(
                onPressed: () async {
                  final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const DeckFormScreen()),
                  );
                  if (created == true) _loadDecks();
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear mazo'),
              ),
            ],
          ),
        ),
      );
    }

    if (_decks.isEmpty) {
      return _buildEmptyState();
    }

    final filteredDecks = _filteredDecks;

    return Column(
      children: [
        if (_isShowingCachedData) _buildOfflineBanner(),
        _buildSearchBar(),
        _buildSortMenu(),
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
                            'Ningún mazo coincide con "$_searchQuery"',
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
                          final result = await Navigator.of(context).push<Object?>(
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