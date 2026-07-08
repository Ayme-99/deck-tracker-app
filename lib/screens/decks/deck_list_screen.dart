import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:deck_tracker_app/widgets/sprite_avatar_group.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../services/deck_service.dart';
import '../../services/stats_service.dart';
import 'deck_detail_screen.dart';
import '../../widgets/slow_loading_indicator.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  final _deckService = DeckService();
  final _statsService = StatsService();
  final _searchController = TextEditingController();

  List<Deck> _decks = [];
  Map<String, Map<String, dynamic>> _overviews = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final decks = await _deckService.getDecks();

      // Trae el overview completo de cada mazo en paralelo (partidas, V-D-E)
      final overviewsList = await Future.wait(
        decks.map((deck) => _statsService.getDeckOverview(deck.id)),
      );

      final overviewsMap = <String, Map<String, dynamic>>{};
      for (var i = 0; i < decks.length; i++) {
        overviewsMap[decks[i].id] = overviewsList[i];
      }

      // Orden por ultima actividad (updatedAt, o createdAt si no existe), mas reciente primero
      final sortedDecks = [...decks]..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

      setState(() {
        _decks = sortedDecks;
        _overviews = overviewsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Deck> get _filteredDecks {
    if (_searchQuery.isEmpty) return _decks;
    return _decks.where((d) => d.name.toLowerCase().contains(_searchQuery)).toList();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mazo'),
        content: Text('¿Seguro que quieres eliminar "${deck.name}"? Esta acción no se puede deshacer.'),
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
      await _deckService.deleteDeck(deck.id);
      _loadDecks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
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

    final filteredDecks = _filteredDecks;

    return Column(
      children: [
        Padding(
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
        ),
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
                      AppSizes.spacingM,
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
                      final wins = overview?['wins'] ?? 0;
                      final losses = overview?['losses'] ?? 0;
                      final ties = overview?['ties'] ?? 0;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
                            );
                            _loadDecks();
                          },
                          onLongPress: () => _showDeckOptions(deck),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.spacingM),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // El sprite escala segun el ancho real de la tarjeta, para que 2 sprites
                                // quepan sin overflow sin importar cuantas columnas haya en el grid.
                                final hasTwoSprites = deck.sprite2 != null;
                                final divisor = hasTwoSprites ? 2.6 : 1.4;
                                final spriteSize = (constraints.maxWidth / divisor).clamp(AppSizes.iconNormal, AppSizes.iconHuge);

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SpriteAvatarGroup(
                                      sprite1: deck.sprite1,
                                      sprite2: deck.sprite2,
                                      size: spriteSize,
                                      centerAlign: true,
                                    ),
                                    const SizedBox(height: AppSizes.spacingS),
                                    Text(
                                      deck.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textS),
                                    ),
                                    const SizedBox(height: AppSizes.spacingXS),
                                    Text(
                                      '${wins}V-${losses}D-${ties}E',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}