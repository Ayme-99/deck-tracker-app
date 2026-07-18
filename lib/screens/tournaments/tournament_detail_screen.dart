import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/match.dart';
import '../../models/opponent_archetype.dart';
import '../../models/tournament.dart';
import '../../services/deck_service.dart';
import '../../services/match_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../services/tournament_service.dart';
import '../../widgets/sprite_avatar_group.dart';
import '../matches/edit_match_screen.dart';
import '../matches/register_match_screen.dart';
import 'tournament_form_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final _tournamentService = TournamentService();
  final _deckService = DeckService();
  final _archetypeService = OpponentArchetypeService();
  final _matchService = MatchService();

  Tournament? _tournament;
  Deck? _deck;
  List<Match> _matches = [];
  Map<String, OpponentArchetype> _archetypesByName = {};
  Map<String, dynamic>? _summary;
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
      final result = await _tournamentService.getTournamentById(widget.tournamentId);
      final tournament = result['tournament'] as Tournament;
      final matchesJson = result['matches'] as List;
      final matches = matchesJson.map((m) => Match.fromJson(m)).toList();

      // Se piden en paralelo: archetypes (para sprites), resumen W-L-T por
      // fase, y el mazo del torneo (si tiene). Orden fijo en la lista para
      // no depender de .last y evitar confusiones si se añade algo mas.
      final archetypesFuture = _archetypeService.getAll();
      final summaryFuture = _tournamentService.getTournamentSummary(tournament.id);
      final deckFuture = tournament.deckId != null ? _deckService.getDeckById(tournament.deckId!) : null;

      final archetypes = await archetypesFuture;
      final summary = await summaryFuture;
      final deck = deckFuture != null ? await deckFuture : null;

      if (!mounted) return;
      setState(() {
        _tournament = tournament;
        _deck = deck;
        _matches = matches;
        _archetypesByName = {for (final a in archetypes) a.name: a};
        _summary = summary;
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

  /// Tiene sentido en cualquier estructura con fase de rondas (swiss,
  /// swiss_elimination, groups_elimination, league): son las estructuras donde no
  /// hay un bracket que deje claro en que puesto quedaste (a diferencia de
  /// una eliminatoria, donde perder en semifinal ya dice tu puesto). Se
  /// guarda como texto compuesto en finalStanding (unico campo que expone
  /// el backend para esto), parseando el valor previo si sigue el patron
  /// "Nº de M" para poder editarlo de nuevo.
  Future<void> _editFinalStanding() async {
    final tournament = _tournament!;
    final match = RegExp(r'^(\d+)º de (\d+)$').firstMatch(tournament.finalStanding ?? '');
    final positionController = TextEditingController(text: match?.group(1) ?? '');
    final totalController = TextEditingController(text: match?.group(2) ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Posición final'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: positionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Puesto obtenido'),
            ),
            const SizedBox(height: AppSizes.spacingM),
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nº total de participantes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      _loadData(); // el cambio de status ya se guardo aunque se cancele el dialogo
      return;
    }

    final position = positionController.text.trim();
    final total = totalController.text.trim();
    // Si se dejan ambos vacios, se borra la posicion final guardada
    final finalStanding = (position.isEmpty || total.isEmpty) ? null : '$positionº de $total';

    try {
      await _tournamentService.updateTournament(tournament.id, {'finalStanding': finalStanding});
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
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
      // EditMatchScreen solo envia los campos que toca el formulario
      // (opponentDeck, prizes, endReason, result, notes), asi que
      // tournamentId/phase/round no se pierden al editar.
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

      // Si la partida borrada tenia ronda, compactamos: todas las partidas
      // de la misma fase con ronda mayor bajan un puesto, para que no
      // queden huecos (ronda 1,3,4 -> 1,2,3) y el conteo automatico de
      // "siguiente ronda" siga siendo valido.
      if (match.phase != null && match.round != null) {
        final toRenumber = _matches
            .where((m) => m.id != match.id && m.phase == match.phase && (m.round ?? 0) > match.round!)
            .toList();
        for (final m in toRenumber) {
          await _matchService.updateMatch(m.id, {'round': m.round! - 1});
        }
      }

      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _handleEditTournament() async {
    final updated = await Navigator.of(context).push<Tournament>(
      MaterialPageRoute(
        builder: (_) => TournamentFormScreen(tournament: _tournament),
      ),
    );
    if (updated != null) _loadData();
  }

  Future<void> _toggleStatus() async {
    final tournament = _tournament!;
    final newStatus = tournament.status == 'finished' ? 'in_progress' : 'finished';
    try {
      await _tournamentService.updateTournament(tournament.id, {'status': newStatus});

      // Al marcar como finalizado, si la estructura tiene fase de rondas
      // (donde no hay bracket que ya diga el puesto) y aun no se ha
      // registrado, se pregunta directamente en vez de esperar a que el
      // usuario recuerde hacerlo a mano desde la tarjeta.
      final hasRoundPhase = (kStructurePhases[tournament.structure] ?? [])
          .any((p) => kRoundBasedPhases.contains(p));
      final alreadySet = tournament.finalStanding != null && tournament.finalStanding!.isNotEmpty;

      if (newStatus == 'finished' && hasRoundPhase && !alreadySet) {
        if (!mounted) return;
        await _editFinalStanding();
      } else {
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  /// Solo tiene sentido en torneos de tipo 'league': aqui no hay forma de
  /// derivar la clasificacion a partir de las partidas propias (no se sabe
  /// la puntuacion del resto de participantes), asi que el usuario la
  /// introduce a mano cuando quiera.
  Future<void> _addStandingSnapshot() async {
    final pointsController = TextEditingController();
    final positionController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir posición'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Puntos'),
            ),
            const SizedBox(height: AppSizes.spacingM),
            TextField(
              controller: positionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Posición en la tabla'),
            ),
            const SizedBox(height: AppSizes.spacingM),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _tournamentService.addStandingSnapshot(
        _tournament!.id,
        points: int.tryParse(pointsController.text),
        position: int.tryParse(positionController.text),
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  String _formatSnapshotDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Widget _buildStandingSection() {
    final snapshots = [..._tournament!.standingSnapshots]..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Clasificación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM)),
                TextButton.icon(
                  onPressed: _addStandingSnapshot,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              ],
            ),
            if (snapshots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.spacingS),
                child: Text(
                  'Registra tu posición y puntos cuando quieras hacer seguimiento',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...snapshots.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXS),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          _formatSnapshotDate(s.date),
                          style: const TextStyle(color: AppColors.muted, fontSize: AppSizes.textXS),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          [
                            if (s.position != null) '${s.position}º puesto',
                            if (s.points != null) '${s.points} pts',
                            if (s.notes != null && s.notes!.isNotEmpty) s.notes!,
                          ].join(' · '),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar torneo'),
        content: Text(
          '¿Eliminar "${_tournament!.name}"? Las partidas ya registradas no se borran, '
          'quedan sueltas fuera del torneo.',
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

    if (confirmed != true) return;

    try {
      await _tournamentService.deleteTournament(_tournament!.id);
      if (!mounted) return;
      Navigator.of(context).pop(true); // vuelve al listado para que se refresque
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  /// Calcula la siguiente ronda disponible en una fase como el maximo
  /// round ya usado + 1 (no un simple conteo de partidas): si se borra una
  /// ronda intermedia, el conteo repetiria un numero ya usado por otra
  /// partida existente, mientras que el maximo nunca genera duplicados.
  int _nextRoundFor(String phase) {
    final roundsInPhase = _matches.where((m) => m.phase == phase).map((m) => m.round ?? 0);
    if (roundsInPhase.isEmpty) return 1;
    return roundsInPhase.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Pregunta en que fase se juega la nueva partida, respetando las fases
  /// validas para la structure del torneo. Si la fase es de las que llevan
  /// ronda (swiss/grupos/liga), la ronda se calcula automaticamente como
  /// la siguiente disponible, sin dejar elegirla a mano.
  Future<void> _handleAddMatch() async {
    final tournament = _tournament!;
    if (_deck == null) return;

    final validPhases = kStructurePhases[tournament.structure] ?? [];
    if (validPhases.isEmpty) return;

    String selectedPhase = validPhases.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final needsRound = kRoundBasedPhases.contains(selectedPhase);
          return AlertDialog(
            title: const Text('¿En qué fase se juega?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPhase,
                  decoration: const InputDecoration(labelText: 'Fase'),
                  items: validPhases
                      .map((p) => DropdownMenuItem(value: p, child: Text(kMatchPhaseLabels[p] ?? p)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedPhase = value!),
                ),
                if (needsRound) ...[
                  const SizedBox(height: AppSizes.spacingM),
                  Text(
                    'Ronda ${_nextRoundFor(selectedPhase)}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    final needsRound = kRoundBasedPhases.contains(selectedPhase);
    final round = needsRound ? _nextRoundFor(selectedPhase) : null;

    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RegisterMatchScreen(
          deck: _deck!,
          tournamentId: tournament.id,
          phase: selectedPhase,
          round: round,
        ),
      ),
    );

    if (registered == true) _loadData();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _resultColor(String result) {
    switch (result) {
      case 'win':
        return AppColors.success;
      case 'loss':
        return AppColors.error;
      default:
        return AppColors.muted;
    }
  }

  /// Agrupa los matches por phase, respetando el orden logico de las fases
  /// (grupos/suiza primero, luego eliminatoria; liga aparte)
  Map<String, List<Match>> _groupByPhase() {
    const phaseOrder = [
      'group_stage',
      'swiss',
      'league_round',
      'round_of_16',
      'quarterfinal',
      'semifinal',
      'final',
    ];

    final grouped = <String, List<Match>>{};
    for (final match in _matches) {
      final phase = match.phase ?? 'sin_fase';
      grouped.putIfAbsent(phase, () => []).add(match);
    }

    // Dentro de cada fase, ordenar por round (los que no tienen round quedan al final)
    for (final list in grouped.values) {
      list.sort((a, b) => (a.round ?? 999).compareTo(b.round ?? 999));
    }

    final orderedKeys = [
      ...phaseOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !phaseOrder.contains(k)),
    ];

    return {for (final k in orderedKeys) k: grouped[k]!};
  }

  Widget _statColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: AppSizes.spacingXS),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS)),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final overall = _summary!['overall'] as Map<String, dynamic>;
    final byPhase = _summary!['byPhase'] as List;
    final totalMatches = overall['totalMatches'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen · $totalMatches partidas',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.spacingM),
            if (totalMatches == 0)
              const Text('Todavía no hay partidas registradas', style: TextStyle(color: AppColors.muted))
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn('${overall['winRate']}%', 'Win rate', AppColors.primaryVariant),
                  _statColumn('${overall['wins']}', 'Victorias', AppColors.success),
                  _statColumn('${overall['losses']}', 'Derrotas', AppColors.error),
                  _statColumn('${overall['ties']}', 'Empates', AppColors.muted),
                ],
              ),
              if (byPhase.length > 1) ...[
                const Divider(height: 32),
                Text(
                  'Por fase',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.spacingS),
                ...byPhase.map((p) {
                  final phase = p['phase'] as String?;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXS),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(kMatchPhaseLabels[phase] ?? phase ?? 'Sin fase'),
                        Text(
                          '${p['wins']}V - ${p['losses']}D - ${p['ties']}E · ${p['winRate']}%',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textS),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Torneo')),
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

    final tournament = _tournament!;
    final isFinished = tournament.status == 'finished';
    final groupedMatches = _groupByPhase();

    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
        // Boton "atras" explicito que siempre devuelve true al hacer pop,
        // para que quien empujo esta pantalla (ej. tras crear el torneo,
        // ver issue #82) sepa que debe refrescar sus datos incluso si el
        // usuario no llego a cambiar nada aqui.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _handleEditTournament();
              } else if (value == 'toggle_status') {
                _toggleStatus();
              } else if (value == 'delete') {
                _confirmDeleteTournament();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar torneo')),
              PopupMenuItem(
                value: 'toggle_status',
                child: Text(isFinished ? 'Marcar como en curso' : 'Marcar como finalizado'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Eliminar torneo')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spacingM,
            AppSizes.spacingM,
            AppSizes.spacingM,
            AppSizes.fabBottomPadding,
          ),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            [
                              _formatDate(tournament.date),
                              if (_deck != null) _deck!.name,
                            ].join(' · '),
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        Chip(
                          label: Text(isFinished ? 'Finalizado' : 'En curso'),
                          backgroundColor: (isFinished ? AppColors.muted : AppColors.success)
                              .withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isFinished ? AppColors.muted : AppColors.success,
                            fontSize: AppSizes.textXS,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    Text(
                      kTournamentStructureLabels[tournament.structure] ?? tournament.structure ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
                    ),
                    if (tournament.location != null && tournament.location!.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spacingXS),
                      Text(tournament.location!, style: const TextStyle(color: AppColors.muted)),
                    ],
                    if (tournament.finalStanding != null && tournament.finalStanding!.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spacingS),
                      Text(
                        '🏆 ${tournament.finalStanding}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if ((kStructurePhases[tournament.structure] ?? [])
                        .any((p) => kRoundBasedPhases.contains(p))) ...[
                      const SizedBox(height: AppSizes.spacingS),
                      InkWell(
                        onTap: _editFinalStanding,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_outlined, size: AppSizes.iconSmall, color: AppColors.muted),
                            const SizedBox(width: AppSizes.spacingXS),
                            Text(
                              tournament.finalStanding == null || tournament.finalStanding!.isEmpty
                                  ? 'Añadir posición final'
                                  : 'Editar posición final',
                              style: const TextStyle(color: AppColors.muted, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (tournament.notes != null && tournament.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spacingS),
                      Text(tournament.notes!, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingL),

            if (_summary != null) ...[
              _buildSummaryCard(),
              const SizedBox(height: AppSizes.spacingL),
            ],

            if (tournament.structure == 'league') ...[
              _buildStandingSection(),
              const SizedBox(height: AppSizes.spacingL),
            ],

            const Text('Partidas', style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.spacingS),

            if (_matches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.spacingM),
                child: Text(
                  'Todavía no hay partidas registradas en este torneo',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...groupedMatches.entries.map((entry) {
                final phase = entry.key;
                final matches = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kMatchPhaseLabels[phase] ?? phase,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSizes.spacingXS),
                      ...matches.map((match) {
                        final archetype = _archetypesByName[match.opponentDeck];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.spacingXS),
                          child: ListTile(
                            leading: archetype?.sprite1 != null
                                ? SpriteAvatarGroup(
                                    sprite1: archetype!.sprite1,
                                    sprite2: archetype.sprite2,
                                    size: AppSizes.iconNormal,
                                  )
                                : CircleAvatar(
                                    backgroundColor: _resultColor(match.result).withValues(alpha: 0.15),
                                    child: Icon(
                                      match.result == 'win'
                                          ? Icons.check
                                          : match.result == 'loss'
                                              ? Icons.close
                                              : Icons.remove,
                                      color: _resultColor(match.result),
                                    ),
                                  ),
                            title: Text('vs ${match.opponentDeck}'),
                            subtitle: Text(
                              [
                                if (match.round != null) 'Ronda ${match.round}',
                                '${match.userPrizes}-${match.opponentPrizes}',
                              ].join(' · '),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                            onTap: () => _showMatchOptions(match),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: _deck != null
          ? FloatingActionButton.extended(
              onPressed: _handleAddMatch,
              icon: const Icon(Icons.add),
              label: const Text('Partida'),
            )
          : null,
    );
  }
}