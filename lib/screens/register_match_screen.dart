import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/match_service.dart';

class RegisterMatchScreen extends StatefulWidget {
  final Deck deck;

  const RegisterMatchScreen({super.key, required this.deck});

  @override
  State<RegisterMatchScreen> createState() => _RegisterMatchScreenState();
}

class _RegisterMatchScreenState extends State<RegisterMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _opponentController = TextEditingController();
  final _notesController = TextEditingController();
  final _matchService = MatchService();

  int _userPrizes = 6;
  int _opponentPrizes = 0;
  String _endReason = 'normal';
  String? _manualResult; // 'win', 'loss', 'tie' - solo se usa cuando hace falta
  bool _isLoading = false;
  String? _errorMessage;

  final _endReasonLabels = const {
    'normal': 'Normal (premios completos)',
    'concession': 'Rendición',
    'no_pokemon': 'Sin Pokémon en banca',
    'time': 'Tiempo agotado',
    'deck_out': 'Mazo agotado',
  };

  bool get _needsManualResult => _userPrizes == _opponentPrizes && _endReason != 'normal';

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _matchService.createMatch(
        deckId: widget.deck.id,
        opponentDeck: _opponentController.text.trim(),
        userPrizes: _userPrizes,
        opponentPrizes: _opponentPrizes,
        endReason: _endReason,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        result: _needsManualResult ? (_manualResult ?? 'tie') : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _prizeCounter(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < 6 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva partida · ${widget.deck.name}')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) async {
                  if (textEditingValue.text.isEmpty) return const [];
                  try {
                    return await _matchService.getOpponentSuggestions(textEditingValue.text);
                  } catch (_) {
                    return const [];
                  }
                },
                onSelected: (selection) => _opponentController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  // Sincroniza el controller interno de Autocomplete con el nuestro
                  controller.addListener(() {
                    _opponentController.text = controller.text;
                  });
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Mazo rival',
                      border: OutlineInputBorder(),
                      helperText: 'Empieza a escribir para ver sugerencias',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduce el mazo rival';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _prizeCounter('Tus premios', _userPrizes, (v) => setState(() => _userPrizes = v)),
                  _prizeCounter('Premios rival', _opponentPrizes, (v) => setState(() => _opponentPrizes = v)),
                ],
              ),
              const SizedBox(height: 8),

              if (_needsManualResult) ...[
                const Text(
                  'Premios empatados con fin de partida especial: indica quién ganó',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'win', label: Text('Gané')),
                    ButtonSegment(value: 'tie', label: Text('Empate')),
                    ButtonSegment(value: 'loss', label: Text('Perdí')),
                  ],
                  selected: {_manualResult ?? 'tie'},
                  onSelectionChanged: (selection) => setState(() => _manualResult = selection.first),
                ),
              ] else
                Center(
                  child: Text(
                    _userPrizes > _opponentPrizes
                        ? '🏆 Victoria'
                        : _userPrizes < _opponentPrizes
                            ? '❌ Derrota'
                            : '🤝 Empate',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _endReason,
                decoration: const InputDecoration(
                  labelText: 'Motivo de fin de partida',
                  border: OutlineInputBorder(),
                ),
                items: _endReasonLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) => setState(() => _endReason = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrar partida'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}