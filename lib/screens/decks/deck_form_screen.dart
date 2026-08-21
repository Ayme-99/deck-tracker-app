import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/card_suggestion.dart';
import '../../models/deck.dart';
import '../../services/card_catalog_service.dart';
import '../../services/deck_service.dart';
import '../../services/tcg_live_deck_parser.dart';
import '../../widgets/sprite_picker.dart';
import '../../widgets/submit_on_enter.dart';

/// Pantalla unificada para crear, editar y duplicar mazos.
/// Si [deck] es null, funciona en modo "crear". Si viene informado, modo "editar".
///
/// [duplicateFrom] (issue #161) precarga el formulario con las cartas/sprites
/// de otro mazo (para partir de una copia y ajustar), pero en modo "crear":
/// al guardar se hace un POST nuevo, no se toca el mazo original. No puede
/// combinarse con [deck] (edicion) al mismo tiempo.
class DeckFormScreen extends StatefulWidget {
  final Deck? deck;
  final Deck? duplicateFrom;

  const DeckFormScreen({super.key, this.deck, this.duplicateFrom})
      : assert(deck == null || duplicateFrom == null, 'No se puede editar y duplicar a la vez');

  @override
  State<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends State<DeckFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _deckService = DeckService();
  final _cardCatalogService = CardCatalogService();

  bool get _isEditing => widget.deck != null;

  String? _sprite1;
  String? _sprite2;
  bool _isLoading = false;
  String? _errorMessage;

  late final List<_CardEntry> _cards;

  @override
  void initState() {
    super.initState();
    final source = widget.deck ?? widget.duplicateFrom;
    _nameController = TextEditingController(
      text: widget.duplicateFrom != null ? '${widget.duplicateFrom!.name} (copia)' : source?.name ?? '',
    );
    _sprite1 = source?.sprite1;
    _sprite2 = source?.sprite2;
    _cards = source?.cards
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

  /// Importa una lista de cartas pegada desde Pokémon TCG Live (issue #176),
  /// sustituyendo la lista actual. El cardId de cada carta importada usa el
  /// mismo fallback que al escribir a mano (slug del nombre): no se intenta
  /// casar contra el catalogo automaticamente, porque los codigos de set de
  /// TCG Live no coinciden con los del catalogo usado aqui (TCGdex). El
  /// usuario puede refinar cada carta despues con el autocompletado normal.
  Future<void> _showImportFromTcgLive() async {
    final controller = TextEditingController();

    final pastedText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar desde Pokémon TCG Live'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_cards.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.spacingS),
                  child: Text(
                    'Esto sustituirá la lista de cartas actual.',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Pega aquí la lista exportada desde TCG Live',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (pastedText == null || !mounted) return;

    final parsed = TcgLiveDeckParser.parse(pastedText);
    if (parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha reconocido ninguna carta en el texto pegado')),
      );
      return;
    }

    setState(() {
      for (final card in _cards) {
        card.nameController.dispose();
        card.quantityController.dispose();
        card.focusNode.dispose();
      }
      _cards
        ..clear()
        ..addAll(parsed.map((c) => _CardEntry(name: c.name, quantity: c.quantity, category: c.category)));
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
          'cards': cardsData,
          'sprite1': _sprite1,
          'sprite2': _sprite2,
        });
      } else {
        await _deckService.createDeck(
          _nameController.text.trim(),
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
      card.focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Mazo' : (widget.duplicateFrom != null ? 'Duplicar Mazo' : 'Nuevo Mazo')),
      ),
      body: SafeArea(
        child: SubmitOnEnter(
          onSubmit: _handleSubmit,
          enabled: !_isLoading,
          child: Form(
          key: _formKey,
          child: ListView(
            // Evita que Flutter desmonte filas fuera de pantalla mientras
            // aun hay una busqueda `optionsBuilder` en vuelo para ellas
            // (causaba un crash al hacer scroll, ver issue de accessibility
            // announce sobre un widget ya desmontado). Un mazo tiene pocas
            // decenas de cartas como mucho, asi que mantenerlas todas
            // montadas es barato.
            cacheExtent: 3000,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _showImportFromTcgLive,
                        icon: const Icon(Icons.content_paste_outlined),
                        tooltip: 'Importar desde Pokémon TCG Live',
                      ),
                      TextButton.icon(
                        onPressed: _addCard,
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir carta'),
                      ),
                    ],
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
                  // Identidad estable por _CardEntry: evita que Flutter
                  // reutilice el Element (y por tanto el controller/estado
                  // del autocompletado) de una fila para una carta distinta
                  // cuando se borra una carta que no esta al final.
                  key: ObjectKey(card),
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingSM),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacingSM),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Autocomplete<CardSuggestion>(
                            // Usamos directamente el controller de la carta
                            // en vez de sincronizar dos controllers a mano:
                            // eso era lo que provocaba el "setState() called
                            // during build" al añadir cartas (se reasignaba
                            // .text en cada build) y ademas pisaba el
                            // realCardId justo despues de seleccionar una
                            // sugerencia.
                            textEditingController: card.nameController,
                            focusNode: card.focusNode,
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
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(labelText: 'Nombre'),
                                // Solo se dispara con edicion real del
                                // usuario (no con asignaciones .text por
                                // codigo), asi que solo aqui perdemos el
                                // cardId real seleccionado antes.
                                onChanged: (_) => card.realCardId = null,
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
                            // Issue #188: sin validador, un campo vacio o con
                            // texto no numerico se guardaba en silencio como
                            // cantidad 1 (int.tryParse(...) ?? 1).
                            validator: (value) {
                              final parsed = int.tryParse(value ?? '');
                              if (parsed == null || parsed < 1) {
                                return 'Nº entero > 0';
                              }
                              return null;
                            },
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
  // Autocomplete exige que focusNode y textEditingController se den juntos
  // o ninguno de los dos (assertion en autocomplete.dart) -- al pasarle
  // nuestro propio nameController hace falta tambien nuestro propio
  // focusNode, o lanza "(focusNode == null) == (textEditingController ==
  // null)' is not true".
  final FocusNode focusNode;
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
        focusNode = FocusNode(),
        originalName = name;
}