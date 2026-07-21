import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../services/deck_service.dart';
import '../../services/tournament_service.dart';
import '../../widgets/submit_on_enter.dart';
import 'tournament_players_screen.dart';

/// Importa un torneo hosted a partir del JSON exportado por otro usuario
/// (issue #76, ver TORNEOS_HOSTED_GDD.md seccion 7). Flujo: pegar el JSON
/// -> analizarlo -> elegir cual jugador de la lista eres tu (opcional) ->
/// si te eliges, elegir tu mazo real -> importar.
class TournamentImportScreen extends StatefulWidget {
  const TournamentImportScreen({super.key});

  @override
  State<TournamentImportScreen> createState() => _TournamentImportScreenState();
}

class _TournamentImportScreenState extends State<TournamentImportScreen> {
  final _tournamentService = TournamentService();
  final _deckService = DeckService();
  final _jsonController = TextEditingController();

  Map<String, dynamic>? _parsedData;
  List<Map<String, dynamic>> _players = [];
  List<Deck> _decks = [];
  String? _selfPlayerOriginalId;
  String? _selfDeckId;
  bool _isAnalyzing = false;
  bool _isImporting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _parsedData = null;
    });

    try {
      final decoded = jsonDecode(_jsonController.text) as Map<String, dynamic>;
      if (decoded['tournament'] == null || decoded['players'] == null || decoded['matches'] == null) {
        throw const FormatException('El JSON no tiene la forma esperada (faltan tournament/players/matches)');
      }
      final players = List<Map<String, dynamic>>.from(decoded['players'] as List);
      final decks = await _deckService.getDecks();

      if (!mounted) return;
      setState(() {
        _parsedData = decoded;
        _players = players;
        _decks = decks;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'JSON inválido: ${e.toString().replaceFirst('Exception: ', '')}';
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _handleImport() async {
    if (_parsedData == null) return;
    if (_selfPlayerOriginalId != null && _selfDeckId == null) {
      setState(() => _errorMessage = 'Selecciona tu mazo real para poder vincular tu inscripción');
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final result = await _tournamentService.importTournament(
        _parsedData!,
        selfPlayerId: _selfPlayerOriginalId,
        selfDeckId: _selfDeckId,
      );
      final newTournamentId = result['tournament']['_id'] as String;

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TournamentPlayersScreen(tournamentId: newTournamentId),
        ),
        result: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar torneo')),
      body: SubmitOnEnter(
        onSubmit: _parsedData == null ? _analyze : _handleImport,
        enabled: !_isAnalyzing && !_isImporting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pega aquí el JSON que te haya pasado quien exportó el torneo.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.spacingM),
              TextField(
                controller: _jsonController,
                maxLines: 10,
                enabled: _parsedData == null,
                decoration: const InputDecoration(
                  labelText: 'JSON del torneo',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSizes.spacingM),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppSizes.spacingM),
              ],

              if (_parsedData == null)
                FilledButton(
                  onPressed: _isAnalyzing ? null : _analyze,
                  child: _isAnalyzing
                      ? const SizedBox(
                          height: AppSizes.spinnerSmall,
                          width: AppSizes.spinnerSmall,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Analizar'),
                )
              else ...[
                Text(
                  '"${_parsedData!['tournament']['name']}" — ${_players.length} jugadores',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.spacingM),

                DropdownButtonFormField<String?>(
                  initialValue: _selfPlayerOriginalId,
                  decoration: const InputDecoration(
                    labelText: '¿Quién eres tú en este torneo?',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Ninguno (solo espectador)')),
                    ..._players.map(
                      (p) => DropdownMenuItem<String?>(
                        value: p['_id'] as String,
                        child: Text(p['name'] as String),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _selfPlayerOriginalId = value;
                    _selfDeckId = null;
                  }),
                ),

                if (_selfPlayerOriginalId != null) ...[
                  const SizedBox(height: AppSizes.spacingM),
                  DropdownButtonFormField<String>(
                    initialValue: _selfDeckId,
                    decoration: const InputDecoration(
                      labelText: 'Tu mazo real',
                      border: OutlineInputBorder(),
                    ),
                    items: _decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                    onChanged: (value) => setState(() => _selfDeckId = value),
                  ),
                ],

                const SizedBox(height: AppSizes.spacingL),
                FilledButton(
                  onPressed: _isImporting ? null : _handleImport,
                  child: _isImporting
                      ? const SizedBox(
                          height: AppSizes.spinnerSmall,
                          width: AppSizes.spinnerSmall,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Importar torneo'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}