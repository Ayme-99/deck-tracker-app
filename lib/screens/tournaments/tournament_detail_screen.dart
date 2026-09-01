import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/match.dart';
import '../../models/opponent_archetype.dart';
import '../../models/tournament.dart';
import '../../services/deck_service.dart';
import '../../services/match_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../services/file_export_service.dart';
import '../../services/losing_streak_service.dart';
import '../../services/match_csv_formatter.dart';
import '../../services/pending_delete_controller.dart';
import '../../services/share_service.dart';
import '../../services/share_text_formatter.dart';
import '../../services/tournament_service.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../matches/edit_match_screen.dart';
import '../matches/register_match_screen.dart';
import 'tournament_detail/tournament_header_card.dart';
import 'tournament_detail/tournament_matches_list.dart';
import 'tournament_detail/tournament_standing_section.dart';
import 'tournament_detail/tournament_summary_card.dart';
import 'tournament_detail/edit_final_standing_dialog.dart';
import 'tournament_detail/add_standing_snapshot_dialog.dart';
import 'tournament_detail/select_match_phase_dialog.dart';
import 'tournament_detail/match_options_sheet.dart';
import 'tournament_detail/confirm_delete_dialogs.dart';
import 'tournament_form_screen.dart';
import '../../l10n/app_localizations.dart';

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
  final _shareService = ShareService();
  final _fileExportService = FileExportService();
  final _losingStreakService = LosingStreakService();

  Tournament? _tournament;
  Deck? _deck;
  List<Match> _matches = [];
  Map<String, OpponentArchetype> _archetypesByName = {};
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  late final _pendingDeleteMatch = PendingDeleteController<Match>(
    onDelete: (match) async {
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

        if (mounted) _loadData();
      } catch (e) {
        if (!mounted) return;
        setState(() => _matches = [match, ..._matches]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).matchDeleteError(e.toString().replaceFirst('Exception: ', '')))),
        );
      }
    },
    onRemoveLocally: (m) => setState(() => _matches = _matches.where((x) => x.id != m.id).toList()),
    onRestoreLocally: (m) => setState(() => _matches = [m, ..._matches]),
    buildMessage: (m) => AppLocalizations.of(context).matchDeletedSnackbar(m.opponentDeck),
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

      // Filtra partidas con un borrado pendiente (SnackBar de deshacer
      // todavia abierto), para que este reload no las haga reaparecer.
      final pendingIds = _pendingDeleteMatch.pendingItems.map((m) => m.id).toSet();

      setState(() {
        _tournament = tournament;
        _deck = deck;
        _matches = matches.where((m) => !pendingIds.contains(m.id)).toList();
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
  /// el backend para esto). El dialogo (ver tournament_detail/
  /// edit_final_standing_dialog.dart) ya valida que ambos campos esten
  /// vacios (borra la posicion) o sean numeros positivos validos (issue
  /// #187).
  Future<void> _editFinalStanding() async {
    final tournament = _tournament!;
    final result = await showEditFinalStandingDialog(context, currentFinalStanding: tournament.finalStanding);

    if (result == null || !mounted) {
      _loadData(); // el cambio de status ya se guardo aunque se cancele el dialogo
      return;
    }

    final finalStanding = result.position == null || result.total == null
        ? null
        : formatFinalStanding(result.position!, result.total!);

    try {
      await _tournamentService.updateTournament(tournament.id, {'finalStanding': finalStanding});
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveError(e.toString().replaceFirst('Exception: ', '')))),
      );
    }
  }

  Future<void> _showMatchOptions(Match match) async {
    final action = await showMatchOptionsSheet(context);

    if (!mounted) return;

    if (action == 'edit') {
      // EditMatchScreen solo envia los campos que toca el formulario
      // (opponentDeck, prizes, endReason, result, notes), asi que
      // tournamentId/phase/round no se pierden al editar.
      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EditMatchScreen(match: match)),
      );
      if (updated == true) _loadData();
    } else if (action == 'share') {
      _shareService.shareText(ShareTextFormatter.formatMatch(AppLocalizations.of(context), match, deckName: _deck?.name));
    } else if (action == 'delete') {
      _confirmDeleteMatch(match);
    }
  }

  Future<void> _confirmDeleteMatch(Match match) async {
    final confirmed = await confirmDeleteMatch(context, opponentDeck: match.opponentDeck);
    if (!confirmed || !mounted) return;
    _pendingDeleteMatch.requestDelete(context, match);
  }

  Future<void> _handleEditTournament() async {
    final updated = await Navigator.of(context).push<Tournament>(
      MaterialPageRoute(
        builder: (_) => TournamentFormScreen(tournament: _tournament),
      ),
    );
    if (updated != null) _loadData();
  }

  Future<void> _exportMatchesCsv(Tournament tournament) async {
    final l10n = AppLocalizations.of(context);
    try {
      final fileName = 'partidas_${tournament.name.replaceAll(RegExp(r'[^\w\-]+'), '_')}';
      final exported = await _fileExportService.saveCsv(MatchCsvFormatter.format(l10n, _matches), fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.matchHistoryExported),
          action: SnackBarAction(label: l10n.openAction, onPressed: () => _fileExportService.open(exported)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportError(e.toString().replaceFirst('Exception: ', '')))),
      );
    }
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
        SnackBar(content: Text(AppLocalizations.of(context).updateError(e.toString().replaceFirst('Exception: ', '')))),
      );
    }
  }

  /// Solo tiene sentido en torneos de tipo 'league': aqui no hay forma de
  /// derivar la clasificacion a partir de las partidas propias (no se sabe
  /// la puntuacion del resto de participantes), asi que el usuario la
  /// introduce a mano cuando quiera.
  Future<void> _addStandingSnapshot() async {
    final result = await showAddStandingSnapshotDialog(context);
    if (result == null || !mounted) return;

    try {
      await _tournamentService.addStandingSnapshot(
        _tournament!.id,
        points: result.points,
        position: result.position,
        notes: result.notes,
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveError(e.toString().replaceFirst('Exception: ', '')))),
      );
    }
  }

  Future<void> _confirmDeleteTournament() async {
    final confirmed = await confirmDeleteTournament(context, name: _tournament!.name);
    if (!confirmed || !mounted) return;

    // Igual que en deck_detail_screen.dart: borrar el torneo desde su
    // propio detalle cierra la pantalla, asi que el SnackBar de deshacer
    // no puede vivir aqui. Se delega en tournaments_screen.dart via un
    // resultado especial ('deleted') al hacer pop.
    Navigator.of(context).pop('deleted');
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

    final selectedPhase = await showSelectMatchPhaseDialog(
      context,
      validPhases: validPhases,
      nextRoundFor: _nextRoundFor,
    );

    if (selectedPhase == null || !mounted) return;

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

    if (registered == true) {
      await _loadData();
      if (mounted) _losingStreakService.checkAndWarn(context, _deck!.id);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Scaffold(body: SlowLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tournamentFallbackTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.genericErrorLabel(_errorMessage!), textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.spacingM),
                FilledButton(onPressed: _loadData, child: Text(l10n.retryAction)),
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
              } else if (value == 'share') {
                _shareService.shareText(ShareTextFormatter.formatTournamentSummary(AppLocalizations.of(context), tournament, _summary!));
              } else if (value == 'export_csv') {
                _exportMatchesCsv(tournament);
              } else if (value == 'delete') {
                _confirmDeleteTournament();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.editTournamentTitle)),
              PopupMenuItem(
                value: 'toggle_status',
                child: Text(isFinished ? l10n.markAsInProgress : l10n.markAsFinished),
              ),
              if (_summary != null)
                PopupMenuItem(value: 'share', child: Text(l10n.shareSummaryAction)),
              PopupMenuItem(value: 'export_csv', child: Text(l10n.exportMatchesToCsvAction)),
              PopupMenuItem(value: 'delete', child: Text(l10n.deleteTournamentAction)),
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
            TournamentHeaderCard(
              tournament: tournament,
              deck: _deck,
              onEditFinalStanding: _editFinalStanding,
            ),
            const SizedBox(height: AppSizes.spacingL),

            if (_summary != null) ...[
              TournamentSummaryCard(summary: _summary!),
              const SizedBox(height: AppSizes.spacingL),
            ],

            if (tournament.structure == 'league') ...[
              TournamentStandingSection(
                tournament: tournament,
                onAddSnapshot: _addStandingSnapshot,
              ),
              const SizedBox(height: AppSizes.spacingL),
            ],

            Text(l10n.matchesSectionTitle, style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSizes.spacingS),

            TournamentMatchesList(
              groupedMatches: groupedMatches,
              archetypesByName: _archetypesByName,
              onMatchTap: _showMatchOptions,
            ),
          ],
        ),
      ),
      floatingActionButton: _deck != null
          ? FloatingActionButton.extended(
              onPressed: _handleAddMatch,
              icon: const Icon(Icons.add),
              label: Text(l10n.registerMatchAction),
            )
          : null,
    );
  }
}