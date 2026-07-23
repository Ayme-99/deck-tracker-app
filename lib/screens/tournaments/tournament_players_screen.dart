import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/opponent_archetype.dart';
import '../../models/tournament_player.dart';
import '../../services/archetype_sprite_lookup.dart';
import '../../services/deck_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../services/tournament_service.dart';
import 'tournament_players/player_form_dialog.dart';
import 'tournament_players/player_list_tile.dart';
import 'tournament_rounds_screen.dart';
import 'tournament_standings_screen.dart';
import 'tournament_export_screen.dart';

/// Gestion de jugadores de un torneo hosted (issue #45): alta, baja
/// (drop), edicion y eliminacion. El campo deckArchetype se autocompleta
/// combinando los mazos propios y los arquetipos rivales ya guardados
/// (ver TORNEOS_HOSTED_GDD.md, nota de frontend en seccion 2).
class TournamentPlayersScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentPlayersScreen({super.key, required this.tournamentId});

  @override
  State<TournamentPlayersScreen> createState() => _TournamentPlayersScreenState();
}

class _TournamentPlayersScreenState extends State<TournamentPlayersScreen> {
  final _tournamentService = TournamentService();
  final _deckService = DeckService();
  final _archetypeService = OpponentArchetypeService();

  List<TournamentPlayer> _players = [];
  List<Deck> _decks = [];
  List<OpponentArchetype> _archetypes = [];
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
      final playersFuture = _tournamentService.getPlayers(widget.tournamentId);
      final decksFuture = _deckService.getDecks();
      final archetypesFuture = _archetypeService.getAll();

      final players = await playersFuture;
      final decks = await decksFuture;
      final archetypes = await archetypesFuture;

      if (!mounted) return;
      setState(() {
        _players = players;
        _decks = decks;
        _archetypes = archetypes;
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

  /// Combina nombres de mazos propios + arquetipos rivales ya guardados,
  /// para sugerir en el autocompletado de deckArchetype.
  List<String> get _archetypeSuggestions {
    final names = <String>{
      ..._decks.map((d) => d.name),
      ..._archetypes.map((a) => a.name),
    };
    return names.toList()..sort();
  }

  Future<void> _showPlayerForm({TournamentPlayer? player}) async {
    final result = await showPlayerFormDialog(
      context,
      player: player,
      decks: _decks,
      spriteLookup: _spriteLookup,
      archetypeSuggestions: _archetypeSuggestions,
    );

    if (result == null || !mounted) return;

    try {
      if (player == null) {
        await _tournamentService.createPlayer(
          widget.tournamentId,
          name: result.name,
          deckArchetype: result.deckArchetype,
          isOrganizer: result.isOrganizer,
          deckId: result.deckId,
        );
      } else {
        await _tournamentService.updatePlayer(widget.tournamentId, player.id, {
          'name': result.name,
          'deckArchetype': result.deckArchetype,
          'isOrganizer': result.isOrganizer,
          if (result.isOrganizer) 'deckId': result.deckId,
        });
      }
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _showPlayerOptions(TournamentPlayer player) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar jugador'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: Icon(player.dropped ? Icons.replay : Icons.person_off_outlined),
              title: Text(player.dropped ? 'Reactivar (deshacer baja)' : 'Dar de baja (drop)'),
              onTap: () => Navigator.of(context).pop('toggle_drop'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: const Text('Eliminar jugador'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'edit') {
      _showPlayerForm(player: player);
    } else if (action == 'toggle_drop') {
      try {
        await _tournamentService.updatePlayer(widget.tournamentId, player.id, {'dropped': !player.dropped});
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } else if (action == 'delete') {
      _confirmDelete(player);
    }
  }

  Future<void> _confirmDelete(TournamentPlayer player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar jugador'),
        content: Text(
          '¿Eliminar a "${player.name}"? Las partidas ya registradas contra este jugador no se borran.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _tournamentService.deletePlayer(widget.tournamentId, player.id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  ArchetypeSpriteLookup get _spriteLookup => ArchetypeSpriteLookup(decks: _decks, archetypes: _archetypes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jugadores'),
        // Boton "atras" explicito que siempre devuelve true al hacer pop,
        // para que quien empujo esta pantalla (ej. tras crear un torneo
        // hosted, ver issue #82) sepa que debe refrescar sus datos incluso
        // si el usuario no llego a crear/editar ningun jugador.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Exportar torneo',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TournamentExportScreen(tournamentId: widget.tournamentId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Clasificación',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TournamentStandingsScreen(tournamentId: widget.tournamentId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sports_score),
            tooltip: 'Rondas y emparejamientos',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TournamentRoundsScreen(tournamentId: widget.tournamentId),
              ),
            ),
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
                  child: _players.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) => ListView(
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: const Center(
                                  child: Text(
                                    'Todavía no hay jugadores inscritos',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.spacingM,
                            AppSizes.spacingM,
                            AppSizes.spacingM,
                            AppSizes.fabBottomPadding,
                          ),
                          itemCount: _players.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSizes.spacingS),
                          itemBuilder: (context, index) {
                            final player = _players[index];
                            return PlayerListTile(
                              player: player,
                              spriteLookup: _spriteLookup,
                              onTap: () => _showPlayerOptions(player),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlayerForm(),
        icon: const Icon(Icons.add),
        label: const Text('Jugador'),
      ),
    );
  }
}