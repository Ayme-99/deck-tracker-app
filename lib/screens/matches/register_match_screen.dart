import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../services/match_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../widgets/sprite_picker.dart';

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
  final _archetypeService = OpponentArchetypeService();

  int _userPrizes = 6;
  int _opponentPrizes = 0;
  String _endReason = 'normal';
  String? _manualResult; // 'win', 'loss', 'tie' - solo se usa cuando hace falta
  bool _isLoading = false;
  String? _errorMessage;

  String? _sprite1;
  String? _sprite2;
  String? _lastLookedUpName; // evita repetir la consulta si el nombre no cambio
  FocusNode? _attachedFocusNode; // evita añadir el listener mas de una vez en rebuilds

  final _endReasonLabels = const {
    'normal': 'Normal (premios completos)',
    'concession': 'Rendición',
    'no_pokemon': 'Sin Pokémon en banca',
    'time': 'Tiempo agotado',
    'deck_out': 'Mazo agotado',
  };

  bool get _needsManualResult => _endReason != 'normal';

  Future<void> _lookupArchetype(String name) async {
    if (name.isEmpty || name == _lastLookedUpName) return;
    _lastLookedUpName = name;

    try {
      final archetype = await _archetypeService.getByName(name);
      if (!mounted) return;
      setState(() {
        _sprite1 = archetype.sprite1;
        _sprite2 = archetype.sprite2;
      });
    } catch (_) {
      // Sin archetype guardado aun, no pasa nada: se queda vacio para elegir
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final opponentName = _opponentController.text.trim();

      await _matchService.createMatch(
        deckId: widget.deck.id,
        opponentDeck: opponentName,
        userPrizes: _userPrizes,
        opponentPrizes: _opponentPrizes,
        endReason: _endReason,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        result: _needsManualResult ? (_manualResult ?? 'tie') : null,
      );

      // Guarda/actualiza los sprites asociados a este nombre de rival, si se eligio alguno
      if (_sprite1 != null) {
        await _archetypeService.upsert(opponentName, sprite1: _sprite1, sprite2: _sprite2);
      }

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
        const SizedBox(height: AppSizes.spacingS),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: AppSizes.badgeWidth,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.all(AppSizes.spacingM),
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
                onSelected: (selection) {
                  _opponentController.text = selection;
                  _lookupArchetype(selection);
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  // Sincroniza el controller interno de Autocomplete con el nuestro
                  controller.addListener(() {
                    _opponentController.text = controller.text;
                  });

                  // Engancha el listener de perdida de foco solo una vez, sobre el focusNode real de Autocomplete
                  if (_attachedFocusNode != focusNode) {
                    _attachedFocusNode = focusNode;
                    focusNode.addListener(() {
                      if (!focusNode.hasFocus) {
                        _lookupArchetype(_opponentController.text.trim());
                      }
                    });
                  }

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
              const SizedBox(height: AppSizes.spacingM),

              SpritePicker(
                sprite1: _sprite1,
                sprite2: _sprite2,
                onChanged: (sprites) {
                  setState(() {
                    _sprite1 = sprites[0];
                    _sprite2 = sprites[1];
                  });
                },
              ),
              const SizedBox(height: AppSizes.spacingL),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _prizeCounter('Tus premios', _userPrizes, (v) => setState(() => _userPrizes = v)),
                  _prizeCounter('Premios rival', _opponentPrizes, (v) => setState(() => _opponentPrizes = v)),
                ],
              ),
              const SizedBox(height: AppSizes.spacingS),

              if (_needsManualResult) ...[
                const Text(
                  'Este motivo de fin de partida puede no coincidir con el marcador de premios: indica el resultado real',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppSizes.textS, color: AppColors.warning),
                ),
                const SizedBox(height: AppSizes.spacingS),
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
                    style: const TextStyle(fontSize: AppSizes.textM, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: AppSizes.spacingL),

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
              const SizedBox(height: AppSizes.spacingM),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSizes.spacingM),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingM),
              ],

              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: AppSizes.spinnerSmall,
                        width: AppSizes.spinnerSmall,
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