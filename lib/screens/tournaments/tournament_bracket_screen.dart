import 'package:flutter/material.dart';
import '../../models/tournament_match.dart';
import '../../models/tournament_player.dart';
import '../../services/tournament_service.dart';
import '../../widgets/tournament_bracket/tournament_bracket.dart';

/// Pantalla independiente del bracket (issue #84): navegable libremente
/// con pan + zoom (InteractiveViewer), como un mapa.
///
/// FIX: antes recibia los datos ya cargados como "foto fija" pasada por
/// constructor -- al registrar un resultado desde aqui, se actualizaba
/// el estado de la pantalla de origen (TournamentRoundsScreen) pero NO
/// esta pantalla, que seguia mostrando los datos viejos hasta cerrarla
/// y volver a abrirla. Ahora carga sus propios datos (misma logica que
/// TournamentRoundsScreen) y se refresca tras cada resultado registrado.
class TournamentBracketScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentBracketScreen({super.key, required this.tournamentId});

  @override
  State<TournamentBracketScreen> createState() => _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  final _tournamentService = TournamentService();

  List<TournamentPlayer> _players = [];
  List<TournamentMatch> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final isInitialLoad = _players.isEmpty && _matches.isEmpty;
    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final playersFuture = _tournamentService.getPlayers(widget.tournamentId);
      final matchesFuture = _tournamentService.getHostedMatches(widget.tournamentId);
      final players = await playersFuture;
      final matches = await matchesFuture;

      if (!mounted) return;
      setState(() {
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

  Future<void> _handleMatchTap(TournamentMatch match) async {
    if (match.isBye) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bye: resuelto automáticamente, no requiere partida')),
      );
      return;
    }

    final player1 = _playersById[match.player1Id];
    final player2 = match.player2Id != null ? _playersById[match.player2Id] : null;
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
              const SizedBox(height: 8),
              TextField(
                controller: p2Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Premios de ${player2?.name ?? 'jugador 2'}'),
              ),
              const SizedBox(height: 16),
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

    try {
      await _tournamentService.registerMatchResult(
        widget.tournamentId,
        match.id,
        player1Prizes: int.tryParse(p1Controller.text),
        player2Prizes: int.tryParse(p2Controller.text),
        winnerId: isDraw ? null : winnerId,
        isDraw: isDraw,
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null && _players.isEmpty && _matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bracket')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $_errorMessage', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadData, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bracket')),
      body: TournamentBracket(
        interactive: true,
        phaseOrder: kEliminationPhaseOrder,
        matchesByPhase: _matchesByPhase,
        playersById: _playersById,
        onMatchTap: _handleMatchTap,
      ),
    );
  }
}