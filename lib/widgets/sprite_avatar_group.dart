import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Muestra 1 o 2 sprites en miniatura, o un icono generico (pokebola) si no hay ninguno.
///
/// Por defecto (centerAlign: false), reserva siempre el mismo ancho para 2 sprites
/// y alinea el contenido a la izquierda — util en listas (ListTile), donde el titulo
/// debe quedar alineado sin importar si el mazo tiene 1 o 2 sprites.
///
/// Con centerAlign: true, el grupo se centra sobre si mismo sin reservar hueco extra
/// para un segundo sprite ausente — util en grids/tarjetas donde no hay titulo que alinear.
class SpriteAvatarGroup extends StatelessWidget {
  final String? sprite1;
  final String? sprite2;
  final double size;
  final bool centerAlign;

  const SpriteAvatarGroup({
    super.key,
    this.sprite1,
    this.sprite2,
    this.size = AppSizes.iconLarge,
    this.centerAlign = false,
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

    if (centerAlign) {
      // Sin ancho fijo: el widget mide justo lo que ocupa su contenido, centrado.
      return content;
    }

    // Ancho fijo calculado a partir del size real (no una constante ajena),
    // para que quepa siempre y quede alineado en listas.
    final fixedWidth = size * 2 + AppSizes.spacingXS;

    return SizedBox(
      width: fixedWidth,
      child: Align(
        alignment: Alignment.centerLeft,
        child: content,
      ),
    );
  }
}