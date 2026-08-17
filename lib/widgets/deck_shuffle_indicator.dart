import 'dart:math';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Indicador de carga personalizado (issue #154): un mazo de 3 cartas
/// barajandose en bucle, en vez del CircularProgressIndicator generico por
/// defecto. Pensado para pantallas de carga completas (arranque de la app,
/// cold-start del servidor, listados) -- no para spinners pequeños dentro
/// de botones.
class DeckShuffleIndicator extends StatefulWidget {
  final double size;

  const DeckShuffleIndicator({super.key, this.size = 64});

  @override
  State<DeckShuffleIndicator> createState() => _DeckShuffleIndicatorState();
}

class _DeckShuffleIndicatorState extends State<DeckShuffleIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DeckShufflePainter(t: _controller.value),
        );
      },
    );
  }
}

class _DeckShufflePainter extends CustomPainter {
  final double t;

  _DeckShufflePainter({required this.t});

  static const _cardColors = [
    AppColors.primary,
    AppColors.primaryVariant,
    AppColors.secondary,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cardSize = Size(size.width * 0.42, size.height * 0.62);
    // Amplitud del "riffle": cuanto se separan las cartas al barajar.
    final amplitude = size.width * 0.18;

    for (var i = 0; i < 3; i++) {
      // Cada carta va desfasada un tercio de vuelta, para que no se muevan
      // todas a la vez (efecto de abanico/riffle en vez de solo rebotar).
      final phase = t * 2 * pi + i * (2 * pi / 3);
      final dx = sin(phase) * amplitude;
      final rotation = sin(phase) * 0.35;

      canvas.save();
      canvas.translate(center.dx + dx, center.dy);
      canvas.rotate(rotation);

      final rect = Rect.fromCenter(center: Offset.zero, width: cardSize.width, height: cardSize.height);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      canvas.drawRRect(
        rrect,
        Paint()..color = _cardColors[i % _cardColors.length],
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // Marca central sencilla, para que se lea como el dorso de una carta
      // y no como un simple rectangulo de color.
      canvas.drawCircle(
        Offset.zero,
        cardSize.width * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DeckShufflePainter oldDelegate) => oldDelegate.t != t;
}
