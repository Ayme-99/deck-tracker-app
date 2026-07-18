import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/tournament.dart';
import '../../models/tournament_match.dart';
import '../../models/tournament_player.dart';
import '../../services/tournament_service.dart';
import '../../widgets/tournament_bracket.dart';

/// Pantalla de rondas/emparejamientos de un torneo hosted (issue #46):
/// genera rondas segun la estructura, muestra el bracket de eliminatoria
/// (o listado simple para swiss/liga/grupos) y permite registrar resultados.
class TournamentRoundsScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentRoundsScreen({super.key, required this.tournamentId});

  @override
  State<TournamentRoundsScreen> createState() => _TournamentRoundsScreenState();
}

class _TournamentRoundsScreenState extends State<TournamentRoundsScreen> {
  final _tournamentService = TournamentService();
  final _scrollController = ScrollController();

  Tournament? _tournament;
  List<TournamentPlayer> _players = [];
  List<TournamentMatch> _matches = [];
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

      final tournamentResult = await tournamentFuture;
      final players = await playersFuture;
      final matches = await matchesFuture;

      if (!mounted) return;
      setState(() {
        _tournament = tournamentResult['tournament'] as Tournament;
        _players = players;
        _matches = matches;
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
    await _runAction(() => _tournamentService.advanceBracketRound(widget.tournamentId, phase));
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
    final p1Controller = TextEditingController(text: match.player1Prizes?.toString() ?? '');
    final p2Controller = TextEditingController(text: match.player2Prizes?.toString() ?? '');
    bool isDraw = match.isDraw;
    String? winnerId = match.winnerId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${player1?.name ?? '?'} vs ${player2?.name ?? '?'}'),
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

  Widget _buildRoundBasedList() {
    final roundPhases = _matchesByPhase.keys.where((p) => kRoundBasedPhases.contains(p)).toList();
    if (roundPhases.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final phase in roundPhases) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
            child: Text(
              kTournamentMatchPhaseLabels[phase] ?? phase,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          ...(_matchesByPhase[phase]!..sort((a, b) => (a.round ?? 0).compareTo(b.round ?? 0))).map((match) {
            final p1 = _playersById[match.player1Id];
            final p2 = match.player2Id != null ? _playersById[match.player2Id] : null;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM, vertical: AppSizes.spacingXS),
              child: Card(
                child: ListTile(
                  onTap: () => _handleMatchTap(match),
                  title: Text('${p1?.name ?? '?'} vs ${match.isBye ? 'BYE' : (p2?.name ?? '?')}'),
                  subtitle: Text(
                    [
                      if (match.round != null) 'Ronda ${match.round}',
                      match.status == 'completed'
                          ? (match.isDraw ? 'Empate' : '${match.player1Prizes ?? '-'}-${match.player2Prizes ?? '-'}')
                          : 'Sin resultado',
                    ].join(' · '),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSizes.spacingM),
        ],
      ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rondas y emparejamientos'),
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
            ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: AppSizes.spacingXL),
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
                _buildRoundBasedList(),
                if (_hasEliminationMatches)
                  TournamentBracket(
                    phaseOrder: kEliminationPhaseOrder,
                    matchesByPhase: _matchesByPhase,
                    playersById: _playersById,
                    onMatchTap: _handleMatchTap,
                  ),
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