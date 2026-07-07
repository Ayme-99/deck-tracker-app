import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Muestra 1 o 2 sprites en miniatura, o un icono generico (pokebola) si no hay ninguno.
/// Ocupa siempre el mismo ancho (AppSizes.avatarGroupWidth), tenga 1 o 2 sprites,
/// para que el texto de las filas quede alineado en listas.
class SpriteAvatarGroup extends StatelessWidget {
  final String? sprite1;
  final String? sprite2;
  final double size;

  const SpriteAvatarGroup({
    super.key,
    this.sprite1,
    this.sprite2,
    this.size = AppSizes.iconLarge,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (sprite1 == null) {
      content = CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.transparent,
        child: Icon(Icons.catching_pokemon, size: size, color: AppColors.muted),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(sprite1!),
          ),
          if (sprite2 != null) ...[
            const SizedBox(width: AppSizes.spacingXS),
            CircleAvatar(
              radius: size / 2,
              backgroundColor: Colors.transparent,
              backgroundImage: NetworkImage(sprite2!),
            ),
          ],
        ],
      );
    }

    return SizedBox(
      width: AppSizes.avatarGroupWidth,
      child: Align(
        alignment: Alignment.centerLeft,
        child: content,
      ),
    );
  }
}