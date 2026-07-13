import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/match.dart';
import '../../models/tournament.dart';
import '../../services/deck_service.dart';
import '../../services/tournament_service.dart';
import '../matches/register_match_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final _tournamentService = TournamentService();
  final _deckService = DeckService();

  Tournament? _tournament;
  Deck? _deck;
  List<Match> _matches = [];
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

      Deck? deck;
      if (tournament.deckId != null) {
        deck = await _deckService.getDeckById(tournament.deckId!);
      }

      if (!mounted) return;
      setState(() {
        _tournament = tournament;
        _deck = deck;
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

  Future<void> _toggleStatus() async {
    final tournament = _tournament!;
    final newStatus = tournament.status == 'finished' ? 'in_progress' : 'finished';
    try {
      await _tournamentService.updateTournament(tournament.id, {'status': newStatus});
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
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

  /// Pregunta en que fase (y, si aplica, en que ronda) se juega la nueva
  /// partida, respetando las fases validas para la structure del torneo.
  Future<void> _handleAddMatch() async {
    final tournament = _tournament!;
    if (_deck == null) return;

    final validPhases = kStructurePhases[tournament.structure] ?? [];
    if (validPhases.isEmpty) return;

    String selectedPhase = validPhases.first;
    final roundController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final needsRound = kRoundBasedPhases.contains(selectedPhase);
          return AlertDialog(
            title: const Text('¿En qué fase se juega?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
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
                  TextField(
                    controller: roundController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Número de ronda/jornada'),
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
    final round = needsRound ? int.tryParse(roundController.text) : null;

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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggle_status') {
                _toggleStatus();
              } else if (value == 'delete') {
                _confirmDeleteTournament();
              }
            },
            itemBuilder: (context) => [
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
                    if (tournament.notes != null && tournament.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spacingS),
                      Text(tournament.notes!, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingL),

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
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.spacingXS),
                          child: ListTile(
                            leading: CircleAvatar(
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