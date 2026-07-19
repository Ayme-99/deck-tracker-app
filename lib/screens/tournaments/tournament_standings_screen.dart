import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/tournament_service.dart';

/// Clasificacion en vivo de un torneo hosted (issue #47): puntos, W-L-D
/// y desempates (diferencial de premios, OMW%), reutilizando
/// getHostedStandings (ya ordenado y con posiciones calculadas en backend).
/// Aplica a swiss, swiss_elimination, league y groups_elimination -- en
/// elimination pura no tiene sentido (no hay puntos, solo bracket).
class TournamentStandingsScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentStandingsScreen({super.key, required this.tournamentId});

  @override
  State<TournamentStandingsScreen> createState() => _TournamentStandingsScreenState();
}

class _TournamentStandingsScreenState extends State<TournamentStandingsScreen> {
  final _tournamentService = TournamentService();

  List<Map<String, dynamic>> _standings = [];
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
      final standings = await _tournamentService.getHostedStandings(widget.tournamentId);
      if (!mounted) return;
      setState(() {
        _standings = standings;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clasificación')),
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
                  child: _standings.isEmpty
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
                          padding: const EdgeInsets.all(AppSizes.spacingM),
                          itemCount: _standings.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSizes.spacingXS),
                          itemBuilder: (context, index) => _StandingRow(entry: _standings[index]),
                        ),
                ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _StandingRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dropped = entry['dropped'] == true;
    final position = entry['position'];
    final name = entry['name'] as String;
    final deckArchetype = entry['deckArchetype'] as String?;
    final wins = entry['wins'];
    final losses = entry['losses'];
    final draws = entry['draws'];
    final points = entry['points'];
    final prizeDifferential = entry['prizeDifferential'];
    final omwPercentage = entry['omwPercentage'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM, vertical: AppSizes.spacingS),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$position',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
              ),
            ),
            const SizedBox(width: AppSizes.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: dropped ? TextDecoration.lineThrough : null,
                      color: dropped ? AppColors.muted : null,
                    ),
                  ),
                  if (deckArchetype != null && deckArchetype.isNotEmpty)
                    Text(
                      deckArchetype,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$points pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
                ),
                Text(
                  '${wins}V-${losses}D-${draws}E',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS),
                ),
                Text(
                  'Dif. $prizeDifferential · OMW $omwPercentage%',
                  style: const TextStyle(color: AppColors.muted, fontSize: AppSizes.textXS),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}