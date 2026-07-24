import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/opponent_archetype.dart';
import '../../models/tournament.dart';
import '../../services/deck_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../services/tournament_service.dart';
import '../../widgets/sprite_avatar_group.dart';
import '../decks/deck_detail_screen.dart';
import '../tournaments/tournament_detail_screen.dart';
import '../tournaments/tournament_players_screen.dart';
import '../../widgets/slow_loading_indicator.dart';

/// Búsqueda unificada sobre mazos, torneos y rivales (issue #131).
///
/// Versión inicial: busca sobre los datos ya cargados en cliente (sin
/// endpoint de búsqueda nuevo en el backend), siguiendo el mismo patrón de
/// filtrado local que ya usaba deck_list_screen.dart.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _deckService = DeckService();
  final _tournamentService = TournamentService();
  final _archetypeService = OpponentArchetypeService();
  final _searchController = TextEditingController();

  List<Deck> _decks = [];
  List<Tournament> _tournaments = [];
  List<OpponentArchetype> _archetypes = [];
  String _query = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _deckService.getDecks(),
        _tournamentService.getTournaments(limit: 1000),
        _archetypeService.getAll(),
      ]);

      if (!mounted) return;
      setState(() {
        _decks = results[0] as List<Deck>;
        _tournaments = results[1] as List<Tournament>;
        _archetypes = results[2] as List<OpponentArchetype>;
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

  List<Deck> get _matchingDecks =>
      _decks.where((d) => d.name.toLowerCase().contains(_query)).toList();

  List<Tournament> get _matchingTournaments =>
      _tournaments.where((t) => t.name.toLowerCase().contains(_query)).toList();

  List<OpponentArchetype> get _matchingArchetypes =>
      _archetypes.where((a) => a.name.toLowerCase().contains(_query)).toList();

  Future<void> _openTournament(Tournament tournament) async {
    // Los torneos hosted aun no tienen su propia pantalla de detalle
    // completa (mismo criterio que tournaments_screen.dart).
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => tournament.mode == 'hosted'
            ? TournamentPlayersScreen(tournamentId: tournament.id)
            : TournamentDetailScreen(tournamentId: tournament.id),
      ),
    );
  }

  void _showArchetypeInfo(OpponentArchetype archetype) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(archetype.name),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpriteAvatarGroup(sprite1: archetype.sprite1, sprite2: archetype.sprite2, size: AppSizes.iconLarge),
            const SizedBox(width: AppSizes.spacingM),
            const Expanded(
              child: Text('Consulta su historial completo en la pestaña Rivales de Estadísticas.'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spacingM, bottom: AppSizes.spacingS),
      child: Text(title, style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.isNotEmpty;
    final decks = _matchingDecks;
    final tournaments = _matchingTournaments;
    final archetypes = _matchingArchetypes;
    final hasResults = decks.isNotEmpty || tournaments.isNotEmpty || archetypes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar mazos, torneos, rivales...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _isLoading
          ? const SlowLoadingIndicator()
          : _errorMessage != null
              ? Center(
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
                )
              : !hasQuery
                  ? const Center(
                      child: Text('Escribe para buscar entre tus mazos, torneos y rivales', style: TextStyle(color: AppColors.muted)),
                    )
                  : !hasResults
                      ? Center(
                          child: Text('Sin resultados para "$_query"', style: const TextStyle(color: AppColors.muted)),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppSizes.spacingM),
                          children: [
                            if (decks.isNotEmpty) ...[
                              _sectionHeader('Mazos'),
                              ...decks.map((deck) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(deck.name),
                                      subtitle: Text(deck.format),
                                      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
                                      ),
                                    ),
                                  )),
                            ],
                            if (tournaments.isNotEmpty) ...[
                              _sectionHeader('Torneos'),
                              ...tournaments.map((tournament) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(tournament.name),
                                      subtitle: Text(kTournamentStructureLabels[tournament.structure] ?? tournament.format),
                                      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                                      onTap: () => _openTournament(tournament),
                                    ),
                                  )),
                            ],
                            if (archetypes.isNotEmpty) ...[
                              _sectionHeader('Rivales'),
                              ...archetypes.map((archetype) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: SpriteAvatarGroup(
                                        sprite1: archetype.sprite1,
                                        sprite2: archetype.sprite2,
                                        size: AppSizes.iconNormal,
                                      ),
                                      title: Text(archetype.name),
                                      onTap: () => _showArchetypeInfo(archetype),
                                    ),
                                  )),
                            ],
                          ],
                        ),
    );
  }
}
