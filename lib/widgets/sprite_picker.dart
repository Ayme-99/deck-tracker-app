import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../services/pokemon_service.dart';

/// Selector de hasta 2 sprites de Pokemon, con autocompletado de especies.
/// Componente totalmente controlado: el padre es la fuente de verdad via
/// [sprite1]/[sprite2], y este widget solo notifica cambios via [onChanged].
class SpritePicker extends StatefulWidget {
  final String? sprite1;
  final String? sprite2;
  final ValueChanged<List<String?>> onChanged;

  const SpritePicker({
    super.key,
    required this.sprite1,
    required this.sprite2,
    required this.onChanged,
  });

  @override
  State<SpritePicker> createState() => _SpritePickerState();
}

class _SpritePickerState extends State<SpritePicker> {
  final _pokemonService = PokemonService();
  bool _isSearching = false;

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

    if (widget.sprite1 == null) {
      widget.onChanged([sprite, widget.sprite2]);
    } else {
      widget.onChanged([widget.sprite1, sprite]);
    }
  }

  void _removeSprite(int index) {
    if (index == 0) {
      // el segundo pasa a ocupar el primer puesto
      widget.onChanged([widget.sprite2, null]);
    } else {
      widget.onChanged([widget.sprite1, null]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sprite1 = widget.sprite1;
    final sprite2 = widget.sprite2;
    final canAddMore = sprite2 == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Icono (opcional)', style: AppTextStyles.caption),
        const SizedBox(height: AppSizes.spacingS),

        Row(
          children: [
            if (sprite1 != null) _spriteChip(sprite1, 0),
            if (sprite1 != null) const SizedBox(width: AppSizes.spacingS),
            if (sprite2 != null) _spriteChip(sprite2, 1),
          ],
        ),
        if (sprite1 != null) const SizedBox(height: AppSizes.spacingS),

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
                  labelText: sprite1 == null ? 'Buscar Pokémon' : 'Añadir segundo icono (opcional)',
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