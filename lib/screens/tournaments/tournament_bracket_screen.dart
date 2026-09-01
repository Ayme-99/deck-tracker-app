import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/tournament_match.dart';
import '../../models/tournament_player.dart';
import '../../services/tournament_service.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../../widgets/tournament_bracket/match_result_dialog.dart';
import '../../widgets/tournament_bracket/tournament_bracket.dart';
import '../../l10n/app_localizations.dart';

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
        SnackBar(content: Text(AppLocalizations.of(context).byeNoMatchNeeded)),
      );
      return;
    }

    final player1 = _playersById[match.player1Id];
    final player2 = match.player2Id != null ? _playersById[match.player2Id] : null;

    final result = await showMatchResultDialog(context, match: match, player1: player1, player2: player2);
    if (result == null || !mounted) return;

    try {
      await _tournamentService.registerMatchResult(
        widget.tournamentId,
        match.id,
        player1Prizes: result.player1Prizes,
        player2Prizes: result.player2Prizes,
        winnerId: result.winnerId,
        isDraw: result.isDraw,
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
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Scaffold(body: SlowLoadingIndicator());
    }

    if (_errorMessage != null && _players.isEmpty && _matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bracketTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingM),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bracketTitle)),
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