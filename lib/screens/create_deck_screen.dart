import 'package:flutter/material.dart';
import '../services/deck_service.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _deckService = DeckService();

  String _format = 'Standard';
  bool _isLoading = false;
  String? _errorMessage;

  final List<_CardEntry> _cards = [];

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

  Future<void> _handleCreate() async {
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

      await _deckService.createDeck(
        _nameController.text.trim(),
        _format,
        cardsData,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // true indica que se creo con exito
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
      appBar: AppBar(title: const Text('Nuevo Mazo')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),

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
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cartas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addCard,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir carta'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_cards.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Puedes añadir cartas ahora o más tarde',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

              ..._cards.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: card.quantityController,
                            decoration: const InputDecoration(labelText: 'Cant.'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeCard(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),

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
                onPressed: _isLoading ? null : _handleCreate,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear mazo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardEntry {
  final nameController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  String category = 'pokemon';
}