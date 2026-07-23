import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/opponent_archetype.dart';
import '../../models/tournament.dart';
import '../../models/tournament_match.dart';
import '../../models/tournament_player.dart';
import '../../services/deck_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../services/tournament_service.dart';
import '../../widgets/sprite_avatar_group.dart';
import '../../widgets/tournament_bracket.dart';
import 'tournament_standings_screen.dart';
import 'tournament_bracket_screen.dart';

/// Pantalla de rondas/emparejamientos de un torneo hosted (issue #46):
/// genera rondas segun la estructura, muestra el bracket de eliminatoria
/// (o listado simple para swiss/liga/grupos) y permite registrar resultados.
class TournamentRoundsScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentRoundsScreen({super.key, required this.tournamentId});

  @override
  State<TournamentRoundsScreen> createState() => _TournamentRoundsScreenState();
}

class _TournamentRoundsScreenState extends State<TournamentRoundsScreen> with TickerProviderStateMixin {
  final _tournamentService = TournamentService();
  final _deckService = DeckService();
  final _archetypeService = OpponentArchetypeService();
  final _scrollController = ScrollController();
  // Controla el scroll horizontal del bracket embebido, para poder
  // desplazarlo programaticamente a una fase concreta desde las pestañas
  // combinadas (issue #85), sin perder el arbol completo ni sus conectores.
  final _bracketScrollController = ScrollController();
  TabController? _tabController;
  List<_TabEntry> _tabEntries = [];

  Tournament? _tournament;
  List<TournamentPlayer> _players = [];
  List<TournamentMatch> _matches = [];
  List<Deck> _decks = [];
  List<OpponentArchetype> _archetypes = [];
  bool _isLoading = true;
  bool _isActionRunning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bracketScrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tournamentFuture = _tournamentService.getTournamentById(widget.tournamentId);
      final playersFuture = _tournamentService.getPlayers(widget.tournamentId);
      final matchesFuture = _tournamentService.getHostedMatches(widget.tournamentId);
      final decksFuture = _deckService.getDecks();
      final archetypesFuture = _archetypeService.getAll();

      final tournamentResult = await tournamentFuture;
      final players = await playersFuture;
      final matches = await matchesFuture;
      final decks = await decksFuture;
      final archetypes = await archetypesFuture;

      if (!mounted) return;
      setState(() {
        _tournament = tournamentResult['tournament'] as Tournament;
        _players = players;
        _matches = matches;
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

  Map<String, TournamentPlayer> get _playersById => {for (final p in _players) p.id: p};

  /// Sprites guardados para un nombre de mazo/arquetipo (issue #51): primero
  /// busca entre los mazos propios y, si no, entre los arquetipos rivales.
  (String?, String?) _spritesForName(String? name) {
    if (name == null || name.isEmpty) return (null, null);
    for (final d in _decks) {
      if (d.name == name) return (d.sprite1, d.sprite2);
    }
    for (final a in _archetypes) {
      if (a.name == name) return (a.sprite1, a.sprite2);
    }
    return (null, null);
  }

  Map<String, List<TournamentMatch>> get _matchesByPhase {
    final map = <String, List<TournamentMatch>>{};
    for (final m in _matches) {
      map.putIfAbsent(m.phase, () => []).add(m);
    }
    return map;
  }

  bool get _hasEliminationMatches =>
      _matches.any((m) => kEliminationPhaseOrder.contains(m.phase));

  /// Ultima fase de eliminatoria (excluyendo 3er/4º puesto) que ya tiene
  /// partidas creadas -- la "fase actual" del bracket.
  String? get _currentEliminationPhase {
    for (final phase in kEliminationPhaseOrder.reversed) {
      final hasMain = _matches.any((m) => m.phase == phase && !m.isThirdPlaceMatch);
      if (hasMain) return phase;
    }
    return null;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _isActionRunning = true;
      _errorMessage = null;
    });
    try {
      await action();
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isActionRunning = false);
    }
  }

  Future<void> _askNumber(String title, String label, void Function(int) onConfirm) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continuar')),
        ],
      ),
    );
    final value = int.tryParse(controller.text);
    if (confirmed == true && value != null && mounted) onConfirm(value);
  }

  Future<void> _handleAssignGroups() async {
    await _askNumber('Asignar grupos', 'Jugadores por grupo', (groupSize) {
      _runAction(() => _tournamentService.assignPlayerGroups(widget.tournamentId, groupSize));
    });
  }

  Future<void> _handleGenerateGroupStage() async {
    await _runAction(() => _tournamentService.generateGroupStageRounds(widget.tournamentId));
  }

  Future<void> _handleGenerateLeague() async {
    await _runAction(() => _tournamentService.generateLeagueRounds(widget.tournamentId));
  }

  Future<void> _handleGenerateSwissRound() async {
    await _runAction(() => _tournamentService.generateSwissRound(widget.tournamentId));
  }

  Future<void> _handleGenerateBracket() async {
    final activeIds = _players.where((p) => !p.dropped).map((p) => p.id).toList();
    await _runAction(() => _tournamentService.generateEliminationBracket(
          widget.tournamentId,
          playerIds: activeIds,
          seeded: false,
        ));
  }

  Future<void> _handleClosePhase() async {
    final structure = _tournament!.structure;
    if (structure == 'swiss_elimination') {
      await _askNumber('Cerrar fase suiza', 'Nº de clasificados (top cut)', (topCut) {
        _runAction(() => _tournamentService.closePhaseToElimination(widget.tournamentId, topCut: topCut));
      });
    } else {
      await _askNumber('Cerrar fase de grupos', 'Clasificados por grupo', (qualifiersPerGroup) {
        _runAction(() => _tournamentService.closePhaseToElimination(
              widget.tournamentId,
              qualifiersPerGroup: qualifiersPerGroup,
            ));
      });
    }
  }

  Future<void> _handleAdvanceBracket() async {
    final phase = _currentEliminationPhase;
    if (phase == null) return;

    await _runAction(() async {
      // Se intenta primero resolvePreliminaryEntry (para el caso "ronda
      // previa reducida ya completada"); si el backend responde que este
      // torneo no tenia ninguna ronda previa pendiente -- puede devolver
      // dos mensajes distintos segun el motivo exacto, ver
      // tournamentController.resolvePreliminaryEntry -- se cae de vuelta
      // a advanceBracketRound (avance normal de una fase completa).
      try {
        await _tournamentService.resolvePreliminaryEntry(widget.tournamentId);
      } catch (e) {
        final message = e.toString();
        final noPendingEntry = message.contains('no tenia ronda previa') ||
            message.contains('ninguna entrada a eliminatoria pendiente');
        if (noPendingEntry) {
          await _tournamentService.advanceBracketRound(widget.tournamentId, phase);
        } else {
          rethrow;
        }
      }
    });
  }

  Future<void> _handleMatchTap(TournamentMatch match) async {
    if (match.isBye) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bye: resuelto automáticamente, no requiere partida')),
      );
      return;
    }

    final player1 = _playersById[match.player1Id];
    final player2 = _playersById[match.player2Id];
    final player1Sprites = _spritesForName(player1?.deckArchetype);
    final player2Sprites = _spritesForName(player2?.deckArchetype);
    final p1Controller = TextEditingController(text: match.player1Prizes?.toString() ?? '');
    final p2Controller = TextEditingController(text: match.player2Prizes?.toString() ?? '');
    bool isDraw = match.isDraw;
    String? winnerId = match.winnerId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpriteAvatarGroup(sprite1: player1Sprites.$1, sprite2: player1Sprites.$2, size: AppSizes.iconNormal),
              const SizedBox(width: AppSizes.spacingXS),
              Flexible(
                child: Text(
                  '${player1?.name ?? '?'} vs ${player2?.name ?? '?'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.spacingXS),
              SpriteAvatarGroup(sprite1: player2Sprites.$1, sprite2: player2Sprites.$2, size: AppSizes.iconNormal),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: p1Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Premios de ${player1?.name ?? 'jugador 1'}'),
              ),
              const SizedBox(height: AppSizes.spacingS),
              TextField(
                controller: p2Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Premios de ${player2?.name ?? 'jugador 2'}'),
              ),
              const SizedBox(height: AppSizes.spacingM),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Empate'),
                value: isDraw,
                onChanged: (value) => setDialogState(() => isDraw = value),
              ),
              if (!isDraw)
                RadioGroup<String>(
                  groupValue: winnerId,
                  onChanged: (value) => setDialogState(() => winnerId = value),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Gana ${player1?.name ?? 'jugador 1'}'),
                        value: match.player1Id,
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Gana ${player2?.name ?? 'jugador 2'}'),
                        value: match.player2Id!,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: (!isDraw && winnerId == null) ? null : () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    await _runAction(() => _tournamentService.registerMatchResult(
          widget.tournamentId,
          match.id,
          player1Prizes: int.tryParse(p1Controller.text),
          player2Prizes: int.tryParse(p2Controller.text),
          winnerId: isDraw ? null : winnerId,
          isDraw: isDraw,
        ));
  }

  Widget _buildActions() {
    if (_tournament == null) return const SizedBox.shrink();
    final structure = _tournament!.structure;
    final buttons = <Widget>[];

    if (structure == 'swiss') {
      buttons.add(FilledButton.icon(
        onPressed: _handleGenerateSwissRound,
        icon: const Icon(Icons.add),
        label: const Text('Generar ronda swiss'),
      ));
    } else if (structure == 'league') {
      final hasLeagueMatches = _matches.any((m) => m.phase == 'league_round');
      if (!hasLeagueMatches) {
        buttons.add(FilledButton.icon(
          onPressed: _handleGenerateLeague,
          icon: const Icon(Icons.calendar_month),
          label: const Text('Generar calendario de liga'),
        ));
      }
    } else if (structure == 'elimination') {
      if (!_hasEliminationMatches) {
        buttons.add(FilledButton.icon(
          onPressed: _handleGenerateBracket,
          icon: const Icon(Icons.account_tree),
          label: const Text('Generar bracket'),
        ));
      }
    } else if (structure == 'swiss_elimination') {
      if (!_hasEliminationMatches) {
        buttons.add(FilledButton.icon(
          onPressed: _handleGenerateSwissRound,
          icon: const Icon(Icons.add),
          label: const Text('Generar ronda swiss'),
        ));
        buttons.add(OutlinedButton.icon(
          onPressed: _handleClosePhase,
          icon: const Icon(Icons.flag),
          label: const Text('Cerrar fase suiza'),
        ));
      }
    } else if (structure == 'groups_elimination') {
      final hasGroups = _players.any((p) => p.groupName != null);
      final hasGroupMatches = _matches.any((m) => m.phase == 'group_stage');
      if (!hasGroups) {
        buttons.add(FilledButton.icon(
          onPressed: _handleAssignGroups,
          icon: const Icon(Icons.groups),
          label: const Text('Asignar grupos'),
        ));
      } else if (!hasGroupMatches) {
        buttons.add(FilledButton.icon(
          onPressed: _handleGenerateGroupStage,
          icon: const Icon(Icons.calendar_month),
          label: const Text('Generar calendario de grupos'),
        ));
      } else if (!_hasEliminationMatches) {
        buttons.add(OutlinedButton.icon(
          onPressed: _handleClosePhase,
          icon: const Icon(Icons.flag),
          label: const Text('Cerrar fase de grupos'),
        ));
      }
    }

    // Avanzar el bracket: disponible en cualquier estructura con fase
    // eliminatoria ya iniciada, mientras no se haya llegado a la final
    if (_hasEliminationMatches && _currentEliminationPhase != null && _currentEliminationPhase != 'final') {
      buttons.add(FilledButton.icon(
        onPressed: _handleAdvanceBracket,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Avanzar a la siguiente fase'),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      child: Wrap(spacing: AppSizes.spacingS, runSpacing: AppSizes.spacingS, children: buttons),
    );
  }

  /// Construye la lista de pestañas combinadas: una por cada ronda de las
  /// fases con rondas (swiss/liga/grupos) + una por cada fase de
  /// eliminatoria que ya tenga partidas. Reinicializa el TabController si
  /// el nº de pestañas cambio desde la ultima vez (nueva ronda generada,
  /// fase avanzada, etc.) -- se llama desde build(), es idempotente si
  /// nada cambio.
  void _ensureTabController() {
    final entries = <_TabEntry>[];

    final roundPhases = _matchesByPhase.keys.where((p) => kRoundBasedPhases.contains(p)).toList();
    for (final phase in roundPhases) {
      final rounds = _matchesByPhase[phase]!.map((m) => m.round ?? 0).toSet().toList()..sort();
      for (final r in rounds) {
        entries.add(_TabEntry.round(label: 'Ronda $r', phase: phase, round: r));
      }
    }

    for (final phase in kEliminationPhaseOrder) {
      if ((_matchesByPhase[phase] ?? []).isNotEmpty) {
        entries.add(_TabEntry.phase(label: kTournamentMatchPhaseLabels[phase] ?? phase, phase: phase));
      }
    }

    final sameLength = _tabController != null && _tabController!.length == entries.length;
    if (sameLength) {
      _tabEntries = entries;
      return;
    }

    _tabController?.dispose();
    _tabEntries = entries;
    if (entries.isEmpty) {
      _tabController = null;
      return;
    }
    _tabController = TabController(length: entries.length, vsync: this);
    _tabController!.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    // Fuerza la reconstruccion para que los Offstage reflejen la pestaña
    // recien seleccionada (el listener del TabController por si solo no
    // reconstruye nada).
    if (mounted) setState(() {});

    final entry = _tabEntries[_tabController!.index];
    if (!entry.isPhase) return;

    final phaseIndex = kEliminationPhaseOrder
        .where((p) => (_matchesByPhase[p] ?? []).isNotEmpty)
        .toList()
        .indexOf(entry.phase);
    if (phaseIndex < 0) return;

    final offset = phaseIndex * (TournamentBracket.cardWidth + TournamentBracket.colGap);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bracketScrollController.hasClients) {
        _bracketScrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildCombinedTabs() {
    if (_tabEntries.isEmpty) return const SizedBox.shrink();

    final anyPhaseTab = _tabEntries.any((e) => e.isPhase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final e in _tabEntries) Tab(text: e.label)],
        ),
        Expanded(
          child: Stack(
            children: [
              for (int i = 0; i < _tabEntries.length; i++)
                if (!_tabEntries[i].isPhase)
                  Offstage(
                    offstage: _tabController!.index != i,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM, vertical: AppSizes.spacingS),
                      children: _matchesByPhase[_tabEntries[i].phase]!
                          .where((m) => (m.round ?? 0) == _tabEntries[i].round)
                          .map(_buildMatchCard)
                          .toList(),
                    ),
                  ),
              // El bracket se mantiene siempre montado (Offstage, no
              // eliminado del arbol) para no perder su posicion de scroll
              // al cambiar entre pestañas de fase.
              if (anyPhaseTab)
                Offstage(
                  offstage: !_tabEntries[_tabController!.index].isPhase,
                  // FIX: el arbol del bracket solo se desplazaba en horizontal por
                  // dentro (via scrollController) -- dentro de la caja de altura fija
                  // de las pestañas, con muchas tarjetas en la primera fase (16, y
                  // hasta 32 cuando soportemos 64 jugadores) siempre desbordaba
                  // verticalmente. Se envuelve en un SingleChildScrollView vertical
                  // para que tambien se pueda desplazar hacia abajo dentro de la caja.
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: TournamentBracket(
                      phaseOrder: kEliminationPhaseOrder,
                      matchesByPhase: _matchesByPhase,
                      playersById: _playersById,
                      onMatchTap: _handleMatchTap,
                      // scrollController: _bracketScrollController,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(TournamentMatch match) {
    final p1 = _playersById[match.player1Id];
    final p2 = match.player2Id != null ? _playersById[match.player2Id] : null;
    final p1Sprites = _spritesForName(p1?.deckArchetype);
    final p2Sprites = _spritesForName(p2?.deckArchetype);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingXS),
      child: Card(
        child: ListTile(
          onTap: () => _handleMatchTap(match),
          leading: SpriteAvatarGroup(sprite1: p1Sprites.$1, sprite2: p1Sprites.$2, size: AppSizes.iconNormal),
          trailing: match.isBye
              ? null
              : SpriteAvatarGroup(sprite1: p2Sprites.$1, sprite2: p2Sprites.$2, size: AppSizes.iconNormal),
          title: Text('${p1?.name ?? '?'} vs ${match.isBye ? 'BYE' : (p2?.name ?? '?')}'),
          subtitle: Text(
            match.status == 'completed'
                ? (match.isDraw ? 'Empate' : '${match.player1Prizes ?? '-'}-${match.player2Prizes ?? '-'}')
                : 'Sin resultado',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solo se muestra la pantalla completa de carga en la primera carga
    // (_tournament == null). En recargas posteriores (tras registrar un
    // resultado, generar una ronda, etc.) se mantiene el ListView montado
    // con los datos anteriores hasta que llegan los nuevos, para no perder
    // la posicion de scroll (issue #81).
    if (_isLoading && _tournament == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null && _tournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rondas')),
        body: Center(
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
        ),
      );
    }

    final hasAnyMatch = _matches.isNotEmpty;
    _ensureTabController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rondas y emparejamientos'),
        actions: [
          if (_hasEliminationMatches)
            IconButton(
              icon: const Icon(Icons.fullscreen),
              tooltip: 'Ver bracket a pantalla completa',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TournamentBracketScreen(
                    tournamentId: widget.tournamentId,
                  ),
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
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildActions(),
                if (!hasAnyMatch)
                  const Padding(
                    padding: EdgeInsets.all(AppSizes.spacingL),
                    child: Center(
                      child: Text(
                        'Todavía no hay rondas generadas. Usa el botón de arriba para empezar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ),
                Expanded(child: _buildCombinedTabs()),
              ],
            ),
            if (_isActionRunning)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
/// Descriptor de una pestaña combinada (issue #85): representa o bien una
/// ronda concreta de una fase con rondas (swiss/liga/grupos), o bien una
/// fase de eliminatoria completa (Octavos, Cuartos...). Las de ronda
/// muestran un listado simple; las de fase desplazan el arbol del bracket
/// (ya montado de forma persistente) hasta esa columna.
class _TabEntry {
  final String label;
  final bool isPhase;
  final String phase;
  final int? round;

  _TabEntry.round({required this.label, required this.phase, required this.round}) : isPhase = false;
  _TabEntry.phase({required this.label, required this.phase})
      : isPhase = true,
        round = null;
}