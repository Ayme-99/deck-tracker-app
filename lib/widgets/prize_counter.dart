import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Contador de premios (0-6) con botones +/- (issue #187, ampliacion tras
/// feedback): reemplaza a los campos de texto libre para premios, que no
/// validaban nada -- se podia escribir "T" o cualquier texto y quedaba
/// "valido" en silencio (int.tryParse simplemente lo ignoraba). Extraido de
/// RegisterMatchScreen/EditMatchScreen, que ya usaban este mismo patron,
/// para reutilizarlo tambien en el dialogo de resultado de partidas hosted
/// (match_result_dialog.dart).
class PrizeCounter extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const PrizeCounter({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: AppSizes.spacingS),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: AppSizes.badgeWidth,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppSizes.textXL, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < 6 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
