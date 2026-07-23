import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:deck_tracker_app/services/deck_service.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/match.dart';
import '../../models/opponent_archetype.dart';
import '../../services/stats_service.dart';
import '../../services/match_service.dart';
import '../../services/opponent_archetype_service.dart';
import 'deck_detail/deck_matchups_section.dart';
import 'deck_detail/deck_overview_card.dart';
import 'deck_detail/deck_recent_matches_section.dart';
import '../matches/register_match_screen.dart';
import '../matches/edit_match_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final _statsService = StatsService();
  final _matchService = MatchService();
  final _deckService = DeckService();
  final _archetypeService = OpponentArchetypeService();

  Map<String, dynamic>? _overview;
  List<dynamic> _matchups = [];
  List<Match> _recentMatches = [];
  Map<String, OpponentArchetype> _archetypesByName = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _showMatchOptions(Match match) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar partida'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: const Text('Eliminar partida'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'edit') {
      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EditMatchScreen(match: match)),
      );
      if (updated == true) _loadData();
    } else if (action == 'delete') {
      _confirmDeleteMatch(match);
    }
  }

  Future<void> _confirmDeleteMatch(Match match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar partida'),
        content: Text('¿Eliminar la partida contra "${match.opponentDeck}"?'),
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
      await _matchService.deleteMatch(match.id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mazo'),
        content: Text('¿Seguro que quieres eliminar "${widget.deck.name}"? Esta acción no se puede deshacer.'),
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
      await _deckService.deleteDeck(widget.deck.id);
      if (!mounted) return;
      Navigator.of(context).pop(true); // vuelve al listado para que se refresque
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
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
        _archetypeService.getAll(),
      ]);

      final archetypes = results[3] as List<OpponentArchetype>;

      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _matchups = results[1] as List<dynamic>;
        _recentMatches = results[2] as List<Match>;
        _archetypesByName = {for (final a in archetypes) a.name: a};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => DeckFormScreen(deck: widget.deck)),
                );
                if (updated == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } else if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar mazo')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar mazo')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.spacingM,
                      AppSizes.spacingM,
                      AppSizes.spacingM,
                      AppSizes.fabBottomPadding,
                    ),
                    children: [
                      DeckOverviewCard(overview: _overview!, deckFormat: widget.deck.format),
                      const SizedBox(height: AppSizes.spacingL),
                      DeckMatchupsSection(matchups: _matchups, archetypesByName: _archetypesByName),
                      const SizedBox(height: AppSizes.spacingL),
                      DeckRecentMatchesSection(
                        matches: _recentMatches,
                        archetypesByName: _archetypesByName,
                        onMatchTap: _showMatchOptions,
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final registered = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => RegisterMatchScreen(deck: widget.deck)),
          );
          if (registered == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Partida'),
      ),
    );
  }

}