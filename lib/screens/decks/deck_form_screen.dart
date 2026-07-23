import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/card_suggestion.dart';
import '../../models/deck.dart';
import '../../services/card_catalog_service.dart';
import '../../services/deck_service.dart';
import '../../widgets/sprite_picker.dart';
import '../../widgets/submit_on_enter.dart';

/// Pantalla unificada para crear y editar mazos.
/// Si [deck] es null, funciona en modo "crear". Si viene informado, modo "editar".
class DeckFormScreen extends StatefulWidget {
  final Deck? deck;

  const DeckFormScreen({super.key, this.deck});

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _deckService = DeckService();
  final _cardCatalogService = CardCatalogService();

  bool get _isEditing => widget.deck != null;

  late String _format;
  String? _sprite1;
  String? _sprite2;
  bool _isLoading = false;
  String? _errorMessage;

  late final List<_CardEntry> _cards;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck?.name ?? '');
    _format = widget.deck?.format ?? 'Standard';
    _sprite1 = widget.deck?.sprite1;
    _sprite2 = widget.deck?.sprite2;
    _cards = widget.deck?.cards
            .map((c) => _CardEntry(
                  name: c.name,
                  quantity: c.quantity,
                  category: c.category,
                  originalCardId: c.cardId,
                ))
            .toList() ??
        [];
  }

  void _addCard() {
    setState(() {
      _cards.add(_CardEntry());
    });
  }

  void _removeCard(int index) {
    setState(() {
      _cards.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cardsData = _cards.map((c) {
        final currentName = c.nameController.text.trim();
        // Prioridad del cardId: 1) uno real elegido del catalogo en esta
        // sesion, 2) el que ya tenia guardado si el nombre no ha cambiado
        // (edicion sin tocar esta carta), 3) slug generado a mano como
        // ultimo recurso (issue #12: solo si el catalogo no encontro nada).
        final cardId = c.realCardId ??
            (c.originalCardId != null && currentName == c.originalName
                ? c.originalCardId!
                : currentName.toLowerCase().replaceAll(' ', '-'));
        return {
          'cardId': cardId,
          'name': currentName,
          'quantity': int.tryParse(c.quantityController.text) ?? 1,
          'category': c.category,
        };
      }).toList();

      if (_isEditing) {
        await _deckService.updateDeck(widget.deck!.id, {
          'name': _nameController.text.trim(),
          'format': _format,
          'cards': cardsData,
          'sprite1': _sprite1,
          'sprite2': _sprite2,
        });
      } else {
        await _deckService.createDeck(
          _nameController.text.trim(),
          _format,
          cardsData,
          sprite1: _sprite1,
          sprite2: _sprite2,
        );
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
    _nameController.dispose();
    for (final card in _cards) {
      card.nameController.dispose();
      card.quantityController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Mazo' : 'Nuevo Mazo')),
      body: SafeArea(
        child: SubmitOnEnter(
          onSubmit: _handleSubmit,
          enabled: !_isLoading,
          child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del mazo',
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
              const SizedBox(height: AppSizes.spacingL),

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cartas', style: TextStyle(fontSize: AppSizes.textM, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addCard,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir carta'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingS),

              if (_cards.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingM),
                  child: Text(
                    _isEditing ? 'No hay cartas añadidas' : 'Puedes añadir cartas ahora o más tarde',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),

              ..._cards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingSM),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacingSM),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Autocomplete<CardSuggestion>(
                            optionsBuilder: (value) async {
                              if (value.text.trim().length < 2) return const Iterable<CardSuggestion>.empty();
                              try {
                                return await _cardCatalogService.search(value.text.trim());
                              } catch (_) {
                                // Catalogo no disponible: se sigue permitiendo escribir a mano (issue #12)
                                return const Iterable<CardSuggestion>.empty();
                              }
                            },
                            displayStringForOption: (c) => c.label,
                            onSelected: (selection) {
                              card.nameController.text = selection.name;
                              card.realCardId = selection.cardId;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                              controller.text = card.nameController.text;
                              controller.addListener(() {
                                card.nameController.text = controller.text;
                                // Nombre tocado a mano: ya no se garantiza que
                                // corresponda a la carta real seleccionada antes.
                                card.realCardId = null;
                              });
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(labelText: 'Nombre'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Requerido';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingS),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: card.quantityController,
                            decoration: const InputDecoration(labelText: 'Cant.'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacingS),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: card.category,
                            decoration: const InputDecoration(labelText: 'Tipo'),
                            items: const [
                              DropdownMenuItem(value: 'pokemon', child: Text('Pokémon')),
                              DropdownMenuItem(value: 'trainer', child: Text('Entrenador')),
                              DropdownMenuItem(value: 'energy', child: Text('Energía')),
                            ],
                            onChanged: (value) => setState(() => card.category = value!),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: AppSizes.iconNormal),
                          onPressed: () => _removeCard(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),

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
                    : Text(_isEditing ? 'Guardar cambios' : 'Crear mazo'),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _CardEntry {
  final TextEditingController nameController;
  final TextEditingController quantityController;
  String category;

  /// Nombre con el que se cargo esta carta (al editar un mazo existente),
  /// para saber si el usuario ha tocado el campo o no.
  final String originalName;

  /// cardId ya guardado en el mazo (al editar), se conserva mientras no se
  /// toque el nombre de esta carta.
  final String? originalCardId;

  /// cardId real de pokemontcg.io elegido del autocompletado en esta
  /// sesion (issue #12). Null si es una carta nueva sin elegir sugerencia,
  /// o si el nombre se ha editado a mano tras elegir una.
  String? realCardId;

  _CardEntry({String name = '', int quantity = 1, this.category = 'pokemon', this.originalCardId})
      : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity.toString()),
        originalName = name;
}