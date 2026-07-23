import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../widgets/sprite_avatar_group.dart';

/// Tarjeta de un mazo en el grid del listado (issue #118: extraida de
/// deck_list_screen.dart).
class DeckListTile extends StatelessWidget {
  final Deck deck;
  final int wins;
  final int losses;
  final int ties;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DeckListTile({
    super.key,
    required this.deck,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingM),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // El sprite escala segun el ancho real de la tarjeta, para que 2 sprites
              // quepan sin overflow sin importar cuantas columnas haya en el grid.
              final hasTwoSprites = deck.sprite2 != null;
              final divisor = hasTwoSprites ? 2.6 : 1.4;
              final spriteSize = (constraints.maxWidth / divisor).clamp(AppSizes.iconNormal, AppSizes.iconHuge);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpriteAvatarGroup(
                    sprite1: deck.sprite1,
                    sprite2: deck.sprite2,
                    size: spriteSize,
                    centerAlign: true,
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  Text(
                    deck.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textS),
                  ),
                  const SizedBox(height: AppSizes.spacingXS),
                  Text(
                    '${wins}V-${losses}D-${ties}E',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
