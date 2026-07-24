import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/match.dart';
import '../../models/opponent_archetype.dart';
import '../../services/stats_service.dart';
import '../../services/match_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../services/pending_delete_controller.dart';
import '../../services/share_service.dart';
import '../../services/share_text_formatter.dart';
import 'deck_detail/deck_matchups_section.dart';
import 'deck_detail/deck_overview_card.dart';
import 'deck_detail/deck_recent_matches_section.dart';
import '../../widgets/winrate_chart.dart';
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
  final _archetypeService = OpponentArchetypeService();
  final _shareService = ShareService();

  Map<String, dynamic>? _overview;
  List<dynamic> _matchups = [];
  List<dynamic> _timeline = [];
  List<Match> _recentMatches = [];
  Map<String, OpponentArchetype> _archetypesByName = {};
  String? _streakType;
  int _streakCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  late final _pendingDeleteMatch = PendingDeleteController<Match>(
    onDelete: (match) async {
      try {
        await _matchService.deleteMatch(match.id);
      } catch (e) {
        if (!mounted) return;
        setState(() => _recentMatches = [match, ..._recentMatches]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la partida: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    },
    onRemoveLocally: (m) => setState(() => _recentMatches = _recentMatches.where((x) => x.id != m.id).toList()),
    onRestoreLocally: (m) => setState(() => _recentMatches = [m, ..._recentMatches]),
    buildMessage: (m) => 'Partida contra "${m.opponentDeck}" eliminada',
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pendingDeleteMatch.dispose();
    super.dispose();
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
              leading: const Icon(Icons.share_outlined),
              title: const Text('Compartir partida'),
              onTap: () => Navigator.of(context).pop('share'),
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
    } else if (action == 'share') {
      _shareService.shareText(ShareTextFormatter.formatMatch(match, deckName: widget.deck.name));
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

    if (confirmed != true || !mounted) return;

    _pendingDeleteMatch.requestDelete(context, match);
  }

  /// A diferencia del resto de borrados (que quitan el item de una lista
  /// visible en la misma pantalla), borrar el mazo desde su propio detalle
  /// hace que la pantalla se cierre. El SnackBar de deshacer no puede vivir
  /// aqui -- se delega en deck_list_screen.dart devolviendo un resultado
  /// especial ('deleted') al hacer pop, para que sea la lista quien registre
  /// el borrado pendiente (ver _DeckListScreenState).
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mazo'),
        content: Text('¿Seguro que quieres eliminar "${widget.deck.name}"?'),
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
    Navigator.of(context).pop('deleted');
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
        // issue #144: se traen de golpe hasta 500 partidas y se paginan de
        // 5 en 5 en el propio DeckRecentMatchesSection (Mostrar más/Ocultar),
        // en vez de repetir llamadas de red por cada ampliación.
        _matchService.getMatches(deckId: widget.deck.id, limit: 500),
        _archetypeService.getAll(),
        _statsService.getDeckStreak(widget.deck.id),
        _statsService.getDeckTimeline(widget.deck.id),
      ]);

      final archetypes = results[3] as List<OpponentArchetype>;
      final streak = results[4] as Map<String, dynamic>;

      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _matchups = results[1] as List<dynamic>;
        _recentMatches = results[2] as List<Match>;
        _archetypesByName = {for (final a in archetypes) a.name: a};
        _streakType = streak['streakType'] as String?;
        _streakCount = streak['streakCount'] as int? ?? 0;
        _timeline = results[5] as List<dynamic>;
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
                      DeckOverviewCard(
                        overview: _overview!,
                        deckFormat: widget.deck.format,
                        streakType: _streakType,
                        streakCount: _streakCount,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      WinrateChart(timeline: _timeline),
                      if (_timeline.length >= 2) const SizedBox(height: AppSizes.spacingL),
                      DeckRecentMatchesSection(
                        matches: _recentMatches,
                        archetypesByName: _archetypesByName,
                        onMatchTap: _showMatchOptions,
                      ),
                      const SizedBox(height: AppSizes.spacingL),
                      DeckMatchupsSection(matchups: _matchups, archetypesByName: _archetypesByName),
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