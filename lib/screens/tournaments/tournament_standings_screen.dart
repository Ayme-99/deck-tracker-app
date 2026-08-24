import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/opponent_archetype.dart';
import '../../services/archetype_sprite_lookup.dart';
import '../../services/deck_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../services/tournament_service.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../../widgets/sprite_avatar_group.dart';

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
  final _deckService = DeckService();
  final _archetypeService = OpponentArchetypeService();

  List<Map<String, dynamic>> _standings = [];
  ArchetypeSpriteLookup _spriteLookup = const ArchetypeSpriteLookup(decks: [], archetypes: []);
  bool _isLoading = true;
  String? _errorMessage;

  // Issue #205: en fase de grupos, se agrupa la clasificacion por grupo
  // (tarjetas tipo sorteo de Mundial) en vez de un ranking global unico --
  // antes no habia ningun sitio donde consultar la composicion de cada
  // grupo.
  bool get _hasGroups => _standings.any((e) => e['groupName'] != null);

  Map<String, List<Map<String, dynamic>>> get _standingsByGroup {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final entry in _standings) {
      final group = entry['groupName'] as String? ?? 'Sin grupo';
      map.putIfAbsent(group, () => []).add(entry);
    }
    return map;
  }

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
      final results = await Future.wait([
        _tournamentService.getHostedStandings(widget.tournamentId),
        _deckService.getDecks(),
        _archetypeService.getAll(),
      ]);

      if (!mounted) return;
      setState(() {
        _standings = results[0] as List<Map<String, dynamic>>;
        _spriteLookup = ArchetypeSpriteLookup(
          decks: results[1] as List<Deck>,
          archetypes: results[2] as List<OpponentArchetype>,
        );
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

  // Issue #205: tarjetas por grupo (una por cada grupo, con su ranking
  // interno), como un sorteo de fase de grupos -- reutiliza _StandingRow
  // para no duplicar el formato de cada fila.
  Widget _buildGroupsView() {
    final groupsByName = _standingsByGroup;
    final groupNames = groupsByName.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      child: Wrap(
        spacing: AppSizes.spacingM,
        runSpacing: AppSizes.spacingM,
        children: groupNames.map((groupName) {
          final entries = groupsByName[groupName]!;
          return SizedBox(
            width: 320,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingM,
                      vertical: AppSizes.spacingS,
                    ),
                    color: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      groupName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.spacingS),
                    child: Column(
                      children: entries.map((entry) {
                        final sprites = _spriteLookup.spritesForName(entry['deckArchetype'] as String?);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.spacingXS),
                          child: _StandingRow(entry: entry, sprite1: sprites.$1, sprite2: sprites.$2),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clasificación')),
      body: _isLoading
          ? const SlowLoadingIndicator()
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
                      : _hasGroups
                          ? _buildGroupsView()
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSizes.spacingM),
                              itemCount: _standings.length,
                              separatorBuilder: (context, index) => const SizedBox(height: AppSizes.spacingXS),
                              itemBuilder: (context, index) {
                                final entry = _standings[index];
                                final sprites = _spriteLookup.spritesForName(entry['deckArchetype'] as String?);
                                return _StandingRow(entry: entry, sprite1: sprites.$1, sprite2: sprites.$2);
                              },
                            ),
                ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String? sprite1;
  final String? sprite2;

  const _StandingRow({required this.entry, this.sprite1, this.sprite2});

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
              width: AppSizes.columnWidthS,
              child: Text(
                '$position',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM),
              ),
            ),
            const SizedBox(width: AppSizes.spacingS),
            if (sprite1 != null || sprite2 != null) ...[
              SpriteAvatarGroup(sprite1: sprite1, sprite2: sprite2, size: AppSizes.iconNormal),
              const SizedBox(width: AppSizes.spacingS),
            ],
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