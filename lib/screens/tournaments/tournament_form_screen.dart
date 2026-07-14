import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/tournament.dart';
import '../../services/deck_service.dart';
import '../../services/tournament_service.dart';

/// Pantalla de creacion/edicion de torneo. Soporta ambos modos: 'tracked'
/// (seguimiento del propio historial) y 'hosted' (la app aloja el torneo
/// completo, issue #44). En modo hosted, el mazo no es obligatorio a nivel
/// de torneo (cada jugador llevara el suyo, ver gestion de jugadores);
/// en su lugar se muestran opciones de configuracion segun la estructura
/// elegida (formato de eliminatoria, 3er/4º puesto, ida/vuelta en liga).
///
/// En modo edicion (widget.tournament != null) solo se pueden cambiar
/// nombre, fecha, localizacion y notas -- mode/structure/deckId quedan
/// fijos porque ya puede haber partidas asociadas que dependen de ellos.
class TournamentFormScreen extends StatefulWidget {
  final Tournament? tournament;

  const TournamentFormScreen({super.key, this.tournament});

  @override
  State<TournamentFormScreen> createState() => _TournamentFormScreenState();
}

class _TournamentFormScreenState extends State<TournamentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.tournament?.name ?? '');
  late final _locationController = TextEditingController(text: widget.tournament?.location ?? '');
  late final _notesController = TextEditingController(text: widget.tournament?.notes ?? '');
  final _tournamentService = TournamentService();
  final _deckService = DeckService();

  bool get _isEditing => widget.tournament != null;

  late String _mode = widget.tournament?.mode ?? 'tracked';
  late String _format = widget.tournament?.format ?? 'Standard';
  late String _structure = widget.tournament?.structure ?? 'swiss';
  String? _deckId;
  late DateTime _date = widget.tournament?.date ?? DateTime.now();
  late String _eliminationFormat = widget.tournament?.eliminationFormat ?? 'single_match';
  late bool _thirdPlacePlayoff = widget.tournament?.thirdPlacePlayoff ?? false;
  late bool _leagueDoubleRound = widget.tournament?.leagueDoubleRound ?? false;

  List<Deck> _decks = [];
  bool _isLoadingDecks = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _deckId = widget.tournament?.deckId;
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    try {
      final decks = await _deckService.getDecks();
      if (!mounted) return;
      setState(() {
        _decks = decks;
        // En edicion, respeta el deckId ya asignado al torneo; solo se
        // preselecciona el primer mazo cuando es una creacion nueva.
        if (!_isEditing) {
          _deckId = decks.isNotEmpty ? decks.first.id : null;
        }
        _isLoadingDecks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar tus mazos: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoadingDecks = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String? _deckNameById(String? id) {
    if (id == null) return null;
    for (final d in _decks) {
      if (d.id == id) return d.name;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // El mazo solo es obligatorio en modo tracked; en hosted no hay un
    // unico mazo del torneo (cada jugador lleva el suyo).
    if (_mode == 'tracked' && _deckId == null) {
      setState(() => _errorMessage = 'Necesitas al menos un mazo creado para registrar un torneo');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      Tournament tournament;
      if (_isEditing) {
        tournament = await _tournamentService.updateTournament(widget.tournament!.id, {
          'name': _nameController.text.trim(),
          'date': _date.toIso8601String(),
          'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        });
      } else {
        tournament = await _tournamentService.createTournament(
          name: _nameController.text.trim(),
          mode: _mode,
          format: _format,
          date: _date,
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          structure: _structure,
          deckId: _mode == 'tracked' ? _deckId : null,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          eliminationFormat: _eliminationFormat,
          thirdPlacePlayoff: _thirdPlacePlayoff,
          leagueDoubleRound: _leagueDoubleRound,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop<Tournament>(tournament);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _modeSelector() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Seguimiento propio'),
            selected: _mode == 'tracked',
            onSelected: (_) => setState(() => _mode = 'tracked'),
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: ChoiceChip(
            label: const Text('Alojar torneo'),
            selected: _mode == 'hosted',
            onSelected: (_) => setState(() => _mode = 'hosted'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar torneo' : 'Nuevo torneo')),
      body: SafeArea(
        child: _isLoadingDecks
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  children: [
                    if (!_isEditing) ...[
                      const Text('Modo', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: AppSizes.spacingS),
                      _modeSelector(),
                      const SizedBox(height: AppSizes.spacingM),
                    ],

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del torneo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introduce un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.spacingM),

                    if (_isEditing) ...[
                      // Mazo y estructura ya no se pueden cambiar una vez
                      // creado el torneo: puede haber partidas registradas
                      // que dependen de ellos.
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Mazo', border: OutlineInputBorder()),
                        child: Text(_deckNameById(_deckId) ?? '—'),
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Estructura', border: OutlineInputBorder()),
                        child: Text(kTournamentStructureLabels[_structure] ?? _structure),
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                    ] else ...[
                      if (_mode == 'tracked') ...[
                        if (_decks.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSizes.spacingS),
                            child: Text(
                              'No tienes mazos creados todavía. Crea uno primero para poder asociarlo al torneo.',
                              style: TextStyle(color: AppColors.warning),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _deckId,
                            decoration: const InputDecoration(
                              labelText: 'Mazo',
                              border: OutlineInputBorder(),
                            ),
                            items: _decks
                                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                                .toList(),
                            onChanged: (value) => setState(() => _deckId = value),
                            validator: (value) => value == null ? 'Selecciona un mazo' : null,
                          ),
                        const SizedBox(height: AppSizes.spacingM),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.spacingS),
                          child: Text(
                            'Si tú también participas, podrás vincular tu mazo más adelante desde la gestión de jugadores.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingS),
                      ],

                      DropdownButtonFormField<String>(
                        initialValue: _structure,
                        decoration: const InputDecoration(
                          labelText: 'Estructura del torneo',
                          border: OutlineInputBorder(),
                        ),
                        items: kTournamentStructureLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (value) => setState(() => _structure = value!),
                      ),
                      const SizedBox(height: AppSizes.spacingM),

                      // Configuracion especifica del modo hosted, segun la
                      // estructura elegida (ver TORNEOS_HOSTED_GDD.md).
                      if (_mode == 'hosted') ...[
                        if (kStructuresWithElimination.contains(_structure)) ...[
                          DropdownButtonFormField<String>(
                            initialValue: _eliminationFormat,
                            decoration: const InputDecoration(
                              labelText: 'Formato de eliminatoria',
                              border: OutlineInputBorder(),
                            ),
                            items: kEliminationFormatLabels.entries
                                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                .toList(),
                            onChanged: (value) => setState(() => _eliminationFormat = value!),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Disputar 3er y 4º puesto'),
                            value: _thirdPlacePlayoff,
                            onChanged: (value) => setState(() => _thirdPlacePlayoff = value),
                          ),
                          const SizedBox(height: AppSizes.spacingS),
                        ],
                        if (_structure == 'league') ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Ida y vuelta'),
                            subtitle: const Text('Cada enfrentamiento se juega dos veces'),
                            value: _leagueDoubleRound,
                            onChanged: (value) => setState(() => _leagueDoubleRound = value),
                          ),
                          const SizedBox(height: AppSizes.spacingS),
                        ],
                      ],
                    ],

                    DropdownButtonFormField<String>(
                      initialValue: _format,
                      decoration: const InputDecoration(
                        labelText: 'Formato',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                        DropdownMenuItem(value: 'Expanded', child: Text('Expanded')),
                      ],
                      onChanged: (value) => setState(() => _format = value!),
                    ),
                    const SizedBox(height: AppSizes.spacingM),

                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: AppSizes.iconSmall),
                        ),
                        child: Text(_formatDate(_date)),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingM),

                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Localización (opcional)',
                        border: OutlineInputBorder(),
                      ),
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
                      onPressed: (_isSubmitting || (_mode == 'tracked' && _decks.isEmpty)) ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: AppSizes.spinnerSmall,
                              width: AppSizes.spinnerSmall,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? 'Guardar cambios' : 'Crear torneo'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}