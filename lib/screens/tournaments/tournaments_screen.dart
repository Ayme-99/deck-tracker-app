import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/tournament.dart';
import '../../models/deck.dart';
import '../../services/tournament_service.dart';
import '../../services/deck_service.dart';
import '../../widgets/slow_loading_indicator.dart';
import 'tournament_detail_screen.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  final _tournamentService = TournamentService();
  final _deckService = DeckService();

  List<Tournament> _tournaments = [];
  Map<String, Deck> _decksById = {};
  bool _isLoading = true;
  String? _errorMessage;
  // 'date' (por defecto), 'position' (1º primero) o 'percentage' (mejor % de ranking primero)
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _showTournamentOptions(Tournament tournament) async {
    final isFinished = tournament.status == 'finished';

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isFinished ? Icons.replay : Icons.check_circle_outline),
              title: Text(isFinished ? 'Marcar como en curso' : 'Marcar como finalizado'),
              onTap: () => Navigator.of(context).pop('toggle_status'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: const Text('Eliminar torneo'),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (action == 'toggle_status') {
      _toggleStatus(tournament);
    } else if (action == 'delete') {
      _confirmDelete(tournament);
    }
  }

  Future<void> _toggleStatus(Tournament tournament) async {
    final newStatus = tournament.status == 'finished' ? 'in_progress' : 'finished';
    try {
      await _tournamentService.updateTournament(tournament.id, {'status': newStatus});
      _loadTournaments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _confirmDelete(Tournament tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar torneo'),
        content: Text(
          '¿Eliminar "${tournament.name}"? Las partidas ya registradas no se borran, '
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
      await _tournamentService.deleteTournament(tournament.id);
      _loadTournaments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Se piden en paralelo: los torneos y el listado de mazos, para poder
      // mostrar el nombre/sprite del mazo de cada torneo (el backend solo
      // devuelve deckId, sin poblar el mazo completo)
      final results = await Future.wait([
        _tournamentService.getTournaments(),
        _deckService.getDecks(),
      ]);

      if (!mounted) return;

      final tournaments = results[0] as List<Tournament>;
      final decks = results[1] as List<Deck>;

      setState(() {
        _tournaments = tournaments;
        _decksById = {for (final d in decks) d.id: d};
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Extrae (puesto, total_participantes) del texto guardado en
  /// finalStanding (formato "Nº de M", ver TournamentDetailScreen).
  /// Devuelve null si no hay standing o no sigue ese patron.
  (int, int)? _parseStanding(String? finalStanding) {
    if (finalStanding == null) return null;
    final match = RegExp(r'^(\d+)º de (\d+)$').firstMatch(finalStanding);
    if (match == null) return null;
    return (int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'position':
        return 'Posición';
      case 'percentage':
        return '% Ranking';
      default:
        return 'Fecha';
    }
  }

  /// Torneos sin standing guardado siempre quedan al final al ordenar por
  /// posicion o % ranking, ya que no hay dato con el que compararlos.
  List<Tournament> get _sortedTournaments {
    final list = [..._tournaments];
    switch (_sortBy) {
      case 'position':
        list.sort((a, b) {
          final pa = _parseStanding(a.finalStanding)?.$1;
          final pb = _parseStanding(b.finalStanding)?.$1;
          if (pa == null && pb == null) return 0;
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.compareTo(pb);
        });
        break;
      case 'percentage':
        list.sort((a, b) {
          final sa = _parseStanding(a.finalStanding);
          final sb = _parseStanding(b.finalStanding);
          final pa = sa != null ? sa.$1 / sa.$2 : null;
          final pb = sb != null ? sb.$1 / sb.$2 : null;
          if (pa == null && pb == null) return 0;
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.compareTo(pb);
        });
        break;
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  Widget _statusChip(String status) {
    final isFinished = status == 'finished';
    return Chip(
      label: Text(isFinished ? 'Finalizado' : 'En curso'),
      backgroundColor: isFinished ? AppColors.muted.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isFinished ? AppColors.muted : AppColors.success,
        fontSize: AppSizes.textXS,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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
              Text('Error al cargar torneos: $_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.spacingM),
              FilledButton.icon(
                onPressed: _loadTournaments,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTournaments,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingL,
                        vertical: AppSizes.spacingXL,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events_outlined, size: AppSizes.iconHuge, color: AppColors.muted),
                          const SizedBox(height: AppSizes.spacingM),
                          const Text(
                            'Todavía no tienes torneos',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: AppSizes.spacingS),
                          const Text(
                            'Registra tu primer torneo para hacer seguimiento de tus partidas por fase',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spacingM, AppSizes.spacingS, AppSizes.spacingM, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (value) => setState(() => _sortBy = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'date', child: Text('Fecha')),
                  PopupMenuItem(value: 'position', child: Text('Posición')),
                  PopupMenuItem(value: 'percentage', child: Text('% Ranking')),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort, size: AppSizes.iconSmall, color: AppColors.muted),
                    const SizedBox(width: AppSizes.spacingXS),
                    Text(
                      'Ordenar: $_sortLabel',
                      style: const TextStyle(color: AppColors.muted, fontSize: AppSizes.textS),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTournaments,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              itemCount: _sortedTournaments.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSizes.spacingS),
              itemBuilder: (context, index) {
                final tournament = _sortedTournaments[index];
                final deck = tournament.deckId != null ? _decksById[tournament.deckId] : null;

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TournamentDetailScreen(tournamentId: tournament.id),
                        ),
                      );
                      _loadTournaments(); // recarga por si cambio el estado o se elimino
                    },
                    onLongPress: () => _showTournamentOptions(tournament),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.spacingM),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tournament.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
                                ),
                                const SizedBox(height: AppSizes.spacingXS),
                                Text(
                                  [
                                    _formatDate(tournament.date),
                                    if (deck != null) deck.name,
                                    if (tournament.structure != null)
                                      kTournamentStructureLabels[tournament.structure] ?? tournament.structure!,
                                  ].join(' · '),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textS),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacingS),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tournament.finalStanding != null && tournament.finalStanding!.isNotEmpty) ...[
                                Text(
                                  '🏆 ${tournament.finalStanding}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppSizes.textXS),
                                ),
                                const SizedBox(width: AppSizes.spacingS),
                              ],
                              _statusChip(tournament.status),
                            ],
                          ),
                        ],
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