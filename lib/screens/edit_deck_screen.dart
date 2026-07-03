import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';

class EditDeckScreen extends StatefulWidget {
  final Deck deck;

  const EditDeckScreen({super.key, required this.deck});

  @override
  State<EditDeckScreen> createState() => _EditDeckScreenState();
}

class _EditDeckScreenState extends State<EditDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _deckService = DeckService();

  late String _format;
  bool _isLoading = false;
  String? _errorMessage;

  late final List<_CardEntry> _cards;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck.name);
    _format = widget.deck.format;
    _cards = widget.deck.cards
        .map((c) => _CardEntry(
              name: c.name,
              quantity: c.quantity,
              category: c.category,
            ))
        .toList();
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cardsData = _cards.map((c) => {
            'cardId': c.nameController.text.trim().toLowerCase().replaceAll(' ', '-'),
            'name': c.nameController.text.trim(),
            'quantity': int.tryParse(c.quantityController.text) ?? 1,
            'category': c.category,
          }).toList();

      await _deckService.updateDeck(widget.deck.id, {
        'name': _nameController.text.trim(),
        'format': _format,
        'cards': cardsData,
      });

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
      appBar: AppBar(title: const Text('Editar Mazo')),
      body: SafeArea(
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
                  child: const Text('No hay cartas añadidas', style: TextStyle(color: AppColors.muted)),
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
                          child: TextFormField(
                            controller: card.nameController,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              return null;
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
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),
            ],
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

  _CardEntry({String name = '', int quantity = 1, this.category = 'pokemon'})
      : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(text: quantity.toString());
}