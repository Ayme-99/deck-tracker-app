import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../services/opponent_archetype_service.dart';
import 'sprite_picker.dart';
import '../l10n/app_localizations.dart';

/// Bottom sheet "Editar rival"/"Eliminar historial", reutilizable en
/// cualquier pantalla que liste arquetipos rivales (issue #198: antes vivia
/// duplicado solo en stats_screen.dart, y la busqueda global no ofrecia
/// ninguna accion real sobre un rival encontrado).
///
/// [totalMatches] es opcional: si no se conoce (ej. la busqueda global solo
/// tiene el archetype, no sus stats agregadas), el aviso de borrado omite
/// el conteo de partidas en vez de mostrar un numero inventado.
Future<void> showOpponentOptionsSheet(
  BuildContext context, {
  required String name,
  String? sprite1,
  String? sprite2,
  int? totalMatches,
  required VoidCallback onChanged,
}) async {
  final archetypeService = OpponentArchetypeService();
  final l10n = AppLocalizations.of(context);

  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.editRivalAction),
            onTap: () => Navigator.of(context).pop('edit'),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text(l10n.deleteRivalHistoryAction),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted) return;

  if (action == 'edit') {
    await _editOpponent(context, archetypeService, name, sprite1, sprite2, onChanged);
  } else if (action == 'delete') {
    await _confirmDeleteOpponent(context, archetypeService, name, totalMatches, onChanged);
  }
}

Future<void> _editOpponent(
  BuildContext context,
  OpponentArchetypeService archetypeService,
  String name,
  String? sprite1,
  String? sprite2,
  VoidCallback onChanged,
) async {
  final l10n = AppLocalizations.of(context);
  final nameController = TextEditingController(text: name);
  String? editedSprite1 = sprite1;
  String? editedSprite2 = sprite2;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(l10n.editRivalAction),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.nameFieldLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: AppSizes.spacingM),
              SpritePicker(
                sprite1: editedSprite1,
                sprite2: editedSprite2,
                onChanged: (sprites) => setDialogState(() {
                  editedSprite1 = sprites[0];
                  editedSprite2 = sprites[1];
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelAction)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.saveAction)),
        ],
      ),
    ),
  );

  final newName = nameController.text.trim();
  nameController.dispose();

  if (saved != true || !context.mounted || newName.isEmpty) return;

  try {
    await archetypeService.update(
      name,
      newName: newName != name ? newName : null,
      sprite1: editedSprite1,
      sprite2: editedSprite2,
    );
    onChanged();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.editError(e.toString().replaceFirst('Exception: ', '')))),
    );
  }
}

Future<void> _confirmDeleteOpponent(
  BuildContext context,
  OpponentArchetypeService archetypeService,
  String name,
  int? totalMatches,
  VoidCallback onChanged,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.deleteRivalDeckTitle),
      content: Text(
        totalMatches != null
            ? l10n.deleteRivalConfirmWithCount(name, totalMatches)
            : l10n.deleteRivalConfirmSimple(name),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelAction)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.deleteAction, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await archetypeService.delete(name);
    onChanged();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tournamentDeleteError(name, e.toString().replaceFirst('Exception: ', '')))),
    );
  }
}
