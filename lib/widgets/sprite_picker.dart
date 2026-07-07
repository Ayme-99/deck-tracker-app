import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../services/pokemon_service.dart';

/// Selector de hasta 2 sprites de Pokemon, con autocompletado de especies.
/// Devuelve los cambios via [onChanged] con una lista de 0, 1 o 2 URLs.
class SpritePicker extends StatefulWidget {
  final String? initialSprite1;
  final String? initialSprite2;
  final ValueChanged<List<String?>> onChanged;

  const SpritePicker({
    super.key,
    this.initialSprite1,
    this.initialSprite2,
    required this.onChanged,
  });

  @override
  State<SpritePicker> createState() => _SpritePickerState();
}

class _SpritePickerState extends State<SpritePicker> {
  final _pokemonService = PokemonService();
  final _searchController = TextEditingController();

  String? _sprite1;
  String? _sprite2;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _sprite1 = widget.initialSprite1;
    _sprite2 = widget.initialSprite2;
  }

  void _notifyChange() {
    widget.onChanged([_sprite1, _sprite2]);
  }

  Future<void> _selectSpecies(String speciesName) async {
    setState(() => _isSearching = true);
    final sprite = await _pokemonService.getSprite(speciesName);
    setState(() => _isSearching = false);

    if (sprite == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se encontró sprite para "$speciesName"')),
      );
      return;
    }

    setState(() {
      if (_sprite1 == null) {
        _sprite1 = sprite;
      } else {
        _sprite2 = sprite;
      }
      _searchController.clear();
    });
    _notifyChange();
  }

  void _removeSprite(int index) {
    setState(() {
      if (index == 0) {
        _sprite1 = _sprite2; // el segundo pasa a ser el primero
        _sprite2 = null;
      } else {
        _sprite2 = null;
      }
    });
    _notifyChange();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = _sprite2 == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icono (opcional)', style: AppTextStyles.caption),
        const SizedBox(height: AppSizes.spacingS),

        Row(
          children: [
            if (_sprite1 != null) _spriteChip(_sprite1!, 0),
            if (_sprite1 != null) const SizedBox(width: AppSizes.spacingS),
            if (_sprite2 != null) _spriteChip(_sprite2!, 1),
          ],
        ),
        if (_sprite1 != null) const SizedBox(height: AppSizes.spacingS),

        if (canAddMore)
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) async {
              if (textEditingValue.text.isEmpty) return const [];
              return await _pokemonService.searchSpecies(textEditingValue.text);
            },
            onSelected: _selectSpecies,
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: _sprite1 == null ? 'Buscar Pokémon' : 'Añadir segundo icono (opcional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(AppSizes.spacingS),
                          child: SizedBox(
                            height: AppSizes.spinnerSmall,
                            width: AppSizes.spinnerSmall,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _spriteChip(String spriteUrl, int index) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: NetworkImage(spriteUrl),
      ),
      label: Text(index == 0 ? '1' : '2'),
      onDeleted: () => _removeSprite(index),
    );
  }
}