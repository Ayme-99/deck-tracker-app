import 'dart:async';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/match.dart';
import '../../services/losing_streak_service.dart';
import '../../services/match_service.dart';
import '../../services/opponent_archetype_service.dart';
import '../../services/quick_widget_sync_service.dart';
import '../../widgets/prize_counter.dart';
import '../../widgets/sprite_picker.dart';
import '../../widgets/submit_on_enter.dart';

class RegisterMatchScreen extends StatefulWidget {
  final Deck deck;
  // Si se informan, la partida se registra asociada a un torneo (issue #40)
  final String? tournamentId;
  final String? phase;
  final int? round;

  const RegisterMatchScreen({
    super.key,
    required this.deck,
    this.tournamentId,
    this.phase,
    this.round,
  });

  @override
  State<RegisterMatchScreen> createState() => _RegisterMatchScreenState();
}

class _RegisterMatchScreenState extends State<RegisterMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _opponentController = TextEditingController();
  final _notesController = TextEditingController();
  final _matchService = MatchService();
  final _archetypeService = OpponentArchetypeService();
  final _losingStreakService = LosingStreakService();

  int _userPrizes = 6;
  int _opponentPrizes = 0;
  String _endReason = 'normal';
  String? _manualResult; // 'win', 'loss', 'tie' - solo se usa cuando hace falta
  bool _isLoading = false;
  String? _errorMessage;

  // Registro rapido encadenado (issue #164): copia mutable de widget.round,
  // para poder incrementarlo tras cada partida encadenada sin depender de
  // que el widget se reconstruya con un round distinto.
  late int? _round = widget.round;
  bool _hasRegisteredAny = false;

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

  // Issue #184: se pide resultado manual con CUALQUIER motivo de fin
  // distinto de "Normal", sin importar el marcador de premios -- una
  // rendicion, tiempo agotado o mazo agotado pueden dar la victoria a quien
  // iba perdiendo en premios, asi que el marcador por si solo no basta para
  // saber quien gano. (EditMatchScreen tenia un criterio distinto, mas
  // restrictivo -- se alinea aqui con el de esta pantalla, que es el
  // correcto.)
  bool get _needsManualResult => _endReason != 'normal';

  bool get _canSubmit => !_isLoading && !(_needsManualResult && _manualResult == null);

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

  /// [chainAnother] (issue #164): si es true, tras registrar con exito no
  /// se cierra la pantalla -- se limpia el formulario para registrar la
  /// siguiente partida seguida (misma fase/torneo, ronda incrementada si
  /// aplica), evitando volver a navegar por Mazos > detalle > Registrar
  /// partida en sesiones con varias rondas seguidas.
  Future<void> _handleSubmit({bool chainAnother = false}) async {
    if (!_formKey.currentState!.validate()) return;
    // Issue #184: con premios empatados y motivo de fin especial, no se
    // asume ningun resultado por defecto -- hay que elegirlo a mano.
    if (_needsManualResult && _manualResult == null) return;

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
        result: _needsManualResult ? _manualResult : null,
        tournamentId: widget.tournamentId,
        phase: widget.phase,
        round: _round,
      );

      // Guarda/actualiza los sprites asociados a este nombre de rival, si se eligio alguno
      if (_sprite1 != null) {
        await _archetypeService.upsert(opponentName, sprite1: _sprite1, sprite2: _sprite2);
      }

      // Resincroniza el widget de acceso rapido (issue #132): esta partida
      // puede haber cambiado la racha del mazo mas jugado.
      unawaited(QuickWidgetSyncService().sync());

      if (!mounted) return;

      if (chainAnother) {
        _hasRegisteredAny = true;
        _resetFormForNextMatch();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partida registrada. Lista para la siguiente.')),
        );
        // Issue #167: al quedarse en esta pantalla (a diferencia del flujo
        // normal, que cierra y avisa desde la pantalla de origen) es el
        // sitio natural para el aviso de racha negativa.
        unawaited(_losingStreakService.checkAndWarn(context, widget.deck.id));
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetFormForNextMatch() {
    setState(() {
      _opponentController.clear();
      _notesController.clear();
      _userPrizes = 6;
      _opponentPrizes = 0;
      _endReason = 'normal';
      _manualResult = null;
      _sprite1 = null;
      _sprite2 = null;
      _lastLookedUpName = null;
      if (_round != null) _round = _round! + 1;
    });
    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Issue #164: si se salio de la pantalla (atras/gesto) tras encadenar
      // alguna partida sin pasar por el boton normal "Registrar partida",
      // hay que avisar igualmente a quien nos abrio de que recargue.
      canPop: !_hasRegisteredAny,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasRegisteredAny) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
      appBar: AppBar(title: Text('Nueva partida · ${widget.deck.name}')),
      body: SafeArea(
        child: SubmitOnEnter(
          onSubmit: _handleSubmit,
          enabled: _canSubmit,
          child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            children: [
              if (widget.tournamentId != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, size: AppSizes.iconSmall, color: AppColors.primary),
                      const SizedBox(width: AppSizes.spacingS),
                      Text(
                        [
                          if (widget.phase != null) kMatchPhaseLabels[widget.phase] ?? widget.phase!,
                          if (_round != null) 'Ronda $_round',
                        ].join(' · '),
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.spacingM),
              ],
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
                  PrizeCounter(
                    label: 'Tus premios',
                    value: _userPrizes,
                    onChanged: (v) => setState(() => _userPrizes = v),
                  ),
                  PrizeCounter(
                    label: 'Premios rival',
                    value: _opponentPrizes,
                    onChanged: (v) => setState(() => _opponentPrizes = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingS),

              if (_needsManualResult) ...[
                const Text(
                  'Selecciona quién ganó realmente: no se calcula a partir de los premios, y este resultado es el que se guarda en tus estadísticas',
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
                  // Sin preseleccion (issue #184): antes arrancaba en
                  // "Empate" por defecto y era facil guardar sin darse
                  // cuenta. Ahora hay que elegir explicitamente.
                  emptySelectionAllowed: true,
                  selected: _manualResult == null ? const {} : {_manualResult!},
                  onSelectionChanged: (selection) =>
                      setState(() => _manualResult = selection.isEmpty ? null : selection.first),
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
                onPressed: _canSubmit ? _handleSubmit : null,
                child: _isLoading
                    ? const SizedBox(
                        height: AppSizes.spinnerSmall,
                        width: AppSizes.spinnerSmall,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrar partida'),
              ),
              const SizedBox(height: AppSizes.spacingS),

              // Registro rapido encadenado (issue #164): registra la partida
              // sin cerrar la pantalla, lista para meter la siguiente (util
              // en sesiones con varias rondas seguidas).
              OutlinedButton(
                onPressed: _canSubmit ? () => _handleSubmit(chainAnother: true) : null,
                child: const Text('Registrar y añadir otra'),
              ),
            ],
          ),
          ),
        ),
      ),
      ),
    );
  }
}