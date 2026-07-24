import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Evolución del win-rate de un mazo a lo largo del tiempo (issue #134):
/// una línea por win-rate acumulado, últimas 5 y últimas 10 partidas, en
/// vez del agregado único de DeckOverviewCard. Se dibuja con un
/// CustomPainter simple en vez de añadir una dependencia de charts, dado
/// el volumen de datos esperado por mazo.
class DeckWinrateChart extends StatelessWidget {
  final List<dynamic> timeline;

  const DeckWinrateChart({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.length < 2) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evolución del win-rate', style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSizes.spacingS),
        _Legend(),
        const SizedBox(height: AppSizes.spacingM),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _WinrateChartPainter(timeline: timeline),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendItem(color: AppColors.primaryVariant, label: 'Acumulado'),
        SizedBox(width: AppSizes.spacingM),
        _LegendItem(color: AppColors.secondary, label: 'Últimas 5'),
        SizedBox(width: AppSizes.spacingM),
        _LegendItem(color: AppColors.muted, label: 'Últimas 10'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSizes.spacingXS),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS)),
      ],
    );
  }
}

class _WinrateChartPainter extends CustomPainter {
  final List<dynamic> timeline;

  _WinrateChartPainter({required this.timeline});

  List<Offset> _points(Size size, String key) {
    final n = timeline.length;
    return List.generate(n, (i) {
      final value = (timeline[i][key] as num).toDouble();
      final x = n == 1 ? 0.0 : size.width * i / (n - 1);
      final y = size.height * (1 - value / 100);
      return Offset(x, y);
    });
  }

  void _drawLine(Canvas canvas, Size size, String key, Color color) {
    final points = _points(size, key);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (final fraction in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawLine(canvas, size, 'last10WinRate', AppColors.muted);
    _drawLine(canvas, size, 'last5WinRate', AppColors.secondary);
    _drawLine(canvas, size, 'cumulativeWinRate', AppColors.primaryVariant);
  }

  @override
  bool shouldRepaint(covariant _WinrateChartPainter oldDelegate) => oldDelegate.timeline != timeline;
}
