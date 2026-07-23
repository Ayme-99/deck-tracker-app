import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../../models/deck.dart';
import '../../../models/tournament_player.dart';
import '../../../services/archetype_sprite_lookup.dart';
import '../../../widgets/sprite_avatar_group.dart';
import '../../../widgets/submit_on_enter.dart';

/// Resultado del formulario de alta/edicion de jugador (issue #118: extraido
/// de tournament_players_screen.dart). Solo recoge los datos validados del
/// dialogo -- la pantalla que lo invoca es quien decide si crea o actualiza
/// el jugador (y maneja errores de red), este widget no llama a ningun
/// servicio.
class PlayerFormResult {
  final String name;
  final String? deckArchetype;
  final bool isOrganizer;
  final String? deckId;

  const PlayerFormResult({
    required this.name,
    this.deckArchetype,
    required this.isOrganizer,
    this.deckId,
  });
}

/// Dialogo de alta/edicion de jugador de un torneo hosted: nombre,
/// autocompletado de mazo/arquetipo (con preview del icono ya guardado para
/// ese nombre) y, si el jugador eres tu mismo ("Soy yo"), el mazo real
/// vinculado. Devuelve `null` si se cancela.
Future<PlayerFormResult?> showPlayerFormDialog(
  BuildContext context, {
  TournamentPlayer? player,
  required List<Deck> decks,
  required ArchetypeSpriteLookup spriteLookup,
  required List<String> archetypeSuggestions,
}) async {
  final nameController = TextEditingController(text: player?.name ?? '');
  final archetypeController = TextEditingController(text: player?.deckArchetype ?? '');
  bool isSelf = player?.isOrganizer ?? false;
  String? selfDeckId = player?.deckId;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        void confirm() {
          if (nameController.text.trim().isEmpty) return;
          if (isSelf && selfDeckId == null) return; // no se puede confirmar sin mazo
          Navigator.of(context).pop(true);
        }

        return SubmitOnEnter(
          onSubmit: confirm,
          child: AlertDialog(
            title: Text(player == null ? 'Añadir jugador' : 'Editar jugador'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  Autocomplete<String>(
                    optionsBuilder: (value) {
                      if (value.text.isEmpty) return archetypeSuggestions;
                      return archetypeSuggestions
                          .where((s) => s.toLowerCase().contains(value.text.toLowerCase()));
                    },
                    onSelected: (selection) => archetypeController.text = selection,
                    fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                      controller.text = archetypeController.text;
                      controller.addListener(() => archetypeController.text = controller.text);
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Mazo / arquetipo (opcional)'),
                      );
                    },
                  ),
                  // Preview del icono ya guardado para ese nombre. Si el mazo
                  // es nuevo (sin sprites guardados aun), no se muestra nada.
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: archetypeController,
                    builder: (context, value, _) {
                      final sprites = spriteLookup.spritesForName(value.text.trim());
                      if (sprites.$1 == null && sprites.$2 == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSizes.spacingS),
                        child: Row(
                          children: [
                            SpriteAvatarGroup(sprite1: sprites.$1, sprite2: sprites.$2, size: AppSizes.iconNormal),
                            const SizedBox(width: AppSizes.spacingS),
                            const Text(
                              'Icono guardado para este mazo',
                              style: TextStyle(color: AppColors.muted, fontSize: AppSizes.textXS),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Soy yo'),
                    subtitle: const Text('Vincula esta inscripción a un mazo real tuyo'),
                    value: isSelf,
                    onChanged: (value) => setDialogState(() => isSelf = value),
                  ),
                  if (isSelf) ...[
                    const SizedBox(height: AppSizes.spacingS),
                    DropdownButtonFormField<String>(
                      initialValue: decks.any((d) => d.id == selfDeckId) ? selfDeckId : null,
                      decoration: const InputDecoration(labelText: 'Tu mazo real'),
                      items: decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                      onChanged: (value) => setDialogState(() => selfDeckId = value),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: confirm,
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    ),
  );

  if (confirmed != true) return null;

  return PlayerFormResult(
    name: nameController.text.trim(),
    deckArchetype: archetypeController.text.trim().isEmpty ? null : archetypeController.text.trim(),
    isOrganizer: isSelf,
    deckId: isSelf ? selfDeckId : null,
  );
}
