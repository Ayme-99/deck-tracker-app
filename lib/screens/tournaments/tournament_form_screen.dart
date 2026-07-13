import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/tournament.dart';
import '../../services/deck_service.dart';
import '../../services/tournament_service.dart';

/// Pantalla de creacion de torneo. Por ahora solo soporta mode 'tracked'
/// (seguimiento del propio historial); 'hosted' se deja visible pero
/// deshabilitado con "Próximamente" hasta que se desarrolle (issue #44).
class TournamentFormScreen extends StatefulWidget {
  const TournamentFormScreen({super.key});

  @override
  State<TournamentFormScreen> createState() => _TournamentFormScreenState();
}

class _TournamentFormScreenState extends State<TournamentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _tournamentService = TournamentService();
  final _deckService = DeckService();

  String _format = 'Standard';
  String _structure = 'swiss';
  String? _deckId;
  DateTime _date = DateTime.now();

  List<Deck> _decks = [];
  bool _isLoadingDecks = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    try {
      final decks = await _deckService.getDecks();
      if (!mounted) return;
      setState(() {
        _decks = decks;
        _deckId = decks.isNotEmpty ? decks.first.id : null;
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deckId == null) {
      setState(() => _errorMessage = 'Necesitas al menos un mazo creado para registrar un torneo');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final tournament = await _tournamentService.createTournament(
        name: _nameController.text.trim(),
        mode: 'tracked',
        format: _format,
        date: _date,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        structure: _structure,
        deckId: _deckId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

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
            selected: true,
            onSelected: (_) {}, // unico modo disponible por ahora
          ),
        ),
        const SizedBox(width: AppSizes.spacingS),
        Expanded(
          child: Tooltip(
            message: 'Disponible próximamente',
            child: ChoiceChip(
              label: const Text('Alojar torneo'),
              selected: false,
              onSelected: null, // deshabilitado: modo hosted aun no desarrollado
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo torneo')),
      body: SafeArea(
        child: _isLoadingDecks
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  children: [
                    const Text('Modo', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSizes.spacingS),
                    _modeSelector(),
                    const SizedBox(height: AppSizes.spacingM),

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
                      onPressed: (_isSubmitting || _decks.isEmpty) ? null : _handleSubmit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: AppSizes.spinnerSmall,
                              width: AppSizes.spinnerSmall,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear torneo'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}