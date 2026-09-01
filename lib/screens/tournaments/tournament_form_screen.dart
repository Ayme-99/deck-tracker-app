import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/tournament.dart';
import '../../services/deck_service.dart';
import '../../services/tournament_service.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../../widgets/submit_on_enter.dart';
import 'tournament_players_screen.dart';
import 'tournament_detail_screen.dart';
import '../../l10n/app_localizations.dart';

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
        _errorMessage = AppLocalizations.of(context).decksLoadError(e.toString().replaceFirst('Exception: ', ''));
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
      setState(() => _errorMessage = AppLocalizations.of(context).tournamentDeckRequired);
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

      // Al crear (no editar) un torneo hosted, ir directo a inscribir
      // jugadores en vez de volver al listado -- no tiene sentido pasar
      // por una pantalla intermedia para lo primero que hay que hacer
      // siempre despues de crear un torneo hosted (issue #82).
      if (!_isEditing && _mode == 'hosted') {
        // result: hace que la pantalla que empujo este formulario (home_screen)
        // reciba un valor no nulo y refresque su listado, aunque el usuario
        // no vuelva a pasar por aqui -- sin esto, pushReplacement resuelve
        // el push original con null de inmediato y el torneo "no aparece"
        // en el listado aunque si se haya guardado en el backend.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TournamentPlayersScreen(tournamentId: tournament.id),
          ),
          result: tournament,
        );
      } else if (!_isEditing && _mode == 'tracked') {
        // Mismo criterio que en hosted (issue #82): tras crear, ir directo
        // al detalle en vez de volver al listado -- ahi es donde se
        // empiezan a añadir partidas, paso natural siguiente.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TournamentDetailScreen(tournamentId: tournament.id),
          ),
          result: tournament,
        );
      } else {
        Navigator.of(context).pop<Tournament>(tournament);
      }
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

  /// Campos de mazo/estructura: en edicion son de solo lectura (ya puede
  /// haber partidas que dependan de ellos), en creacion son selects, con
  /// la configuracion especifica de hosted anidada dentro.
  Widget _deckAndStructureFields(AppLocalizations l10n) {
    if (_isEditing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: InputDecoration(labelText: l10n.deckFieldLabel, border: const OutlineInputBorder()),
            child: Text(_deckNameById(_deckId) ?? '—'),
          ),
          const SizedBox(height: AppSizes.spacingM),
          InputDecorator(
            decoration: InputDecoration(labelText: l10n.structureFieldLabel, border: const OutlineInputBorder()),
            child: Text(tournamentStructureLabels(l10n)[_structure] ?? _structure),
          ),
          const SizedBox(height: AppSizes.spacingM),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mode == 'tracked') ...[
          if (_decks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
              child: Text(
                l10n.noDecksYetForTournament,
                style: const TextStyle(color: AppColors.warning),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _deckId,
              decoration: InputDecoration(
                labelText: l10n.deckFieldLabel,
                border: const OutlineInputBorder(),
              ),
              items: _decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
              onChanged: (value) => setState(() => _deckId = value),
              validator: (value) => value == null ? l10n.deckSelectRequired : null,
            ),
          const SizedBox(height: AppSizes.spacingM),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
            child: Text(
              l10n.hostedModeDeckHint,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
        ],

        DropdownButtonFormField<String>(
          initialValue: _structure,
          decoration: InputDecoration(
            labelText: l10n.tournamentStructureFieldLabel,
            border: const OutlineInputBorder(),
          ),
          items: tournamentStructureLabels(l10n).entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (value) => setState(() => _structure = value!),
        ),
        const SizedBox(height: AppSizes.spacingM),

        // Configuracion especifica del modo hosted, segun la
        // estructura elegida (ver TORNEOS_HOSTED_GDD.md).
        if (_mode == 'hosted') _hostedStructureOptions(l10n),
      ],
    );
  }

  /// Formato de eliminatoria + 3er/4º puesto (si la estructura tiene fase
  /// eliminatoria) y opcion de ida/vuelta (si es liga) -- solo aplica en
  /// modo hosted.
  Widget _hostedStructureOptions(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kStructuresWithElimination.contains(_structure)) ...[
          DropdownButtonFormField<String>(
            initialValue: _eliminationFormat,
            decoration: InputDecoration(
              labelText: l10n.eliminationFormatFieldLabel,
              border: const OutlineInputBorder(),
            ),
            items: eliminationFormatLabels(l10n).entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (value) => setState(() => _eliminationFormat = value!),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.thirdPlacePlayoffLabel),
            value: _thirdPlacePlayoff,
            onChanged: (value) => setState(() => _thirdPlacePlayoff = value),
          ),
          const SizedBox(height: AppSizes.spacingS),
        ],
        if (_structure == 'league') ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.doubleRoundLabel),
            subtitle: Text(l10n.doubleRoundSubtitle),
            value: _leagueDoubleRound,
            onChanged: (value) => setState(() => _leagueDoubleRound = value),
          ),
          const SizedBox(height: AppSizes.spacingS),
        ],
      ],
    );
  }

  Widget _modeSelector(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: Text(l10n.trackedModeLabel),
            selected: _mode == 'tracked',
            onSelected: (_) => setState(() => _mode = 'tracked'),
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: ChoiceChip(
            label: Text(l10n.hostedModeLabel),
            selected: _mode == 'hosted',
            onSelected: (_) => setState(() => _mode = 'hosted'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? l10n.editTournamentTitle : l10n.newTournamentTitle)),
      body: SafeArea(
        child: _isLoadingDecks
            ? const SlowLoadingIndicator()
            : SubmitOnEnter(
                onSubmit: _handleSubmit,
                enabled: !_isSubmitting,
                child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  children: [
                    if (!_isEditing) ...[
                      Text(l10n.modeFieldLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: AppSizes.spacingS),
                      _modeSelector(l10n),
                      const SizedBox(height: AppSizes.spacingM),
                    ],

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.tournamentNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.tournamentNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.spacingM),

                    // Mazo y estructura: solo lectura si se esta editando
                    // (puede haber partidas que dependan de ellos), selects
                    // + configuracion especifica de hosted si se esta creando.
                    _deckAndStructureFields(l10n),

                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.dateFieldLabel,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today, size: AppSizes.iconSmall),
                        ),
                        child: Text(_formatDate(_date)),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingM),

                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: l10n.locationFieldLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingM),

                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.notesOptionalLabel,
                        border: const OutlineInputBorder(),
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
                          : Text(_isEditing ? l10n.saveChangesAction : l10n.createTournamentButton),
                    ),
                  ],
                ),
              ),
              ),
      ),
    );
  }
}