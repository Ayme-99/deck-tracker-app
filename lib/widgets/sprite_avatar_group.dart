import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deck_tracker_app/styles.dart';

/// Muestra 1 o 2 sprites en miniatura, o un icono generico (pokebola) si no hay ninguno.
///
/// Los sprites se cargan via CachedNetworkImage, que cachea en disco (persiste entre
/// sesiones de la app) ademas de en memoria, evitando recargas y esperas repetidas.
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

  Widget _sprite(String url) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.catching_pokemon,
          size: size,
          color: AppColors.muted,
        ),
      ),
    );
  }

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
          _sprite(sprite1!),
          if (sprite2 != null) ...[
            const SizedBox(width: AppSizes.spacingXS),
            _sprite(sprite2!),
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