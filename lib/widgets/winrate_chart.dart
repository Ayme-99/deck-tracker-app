import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Evolución del win-rate a lo largo del tiempo (issue #134 para un mazo
/// concreto, issue #88/#145 para el agregado global): una línea por
/// win-rate acumulado, últimas 5 y últimas 10 partidas. Se dibuja con un
/// CustomPainter simple en vez de añadir una dependencia de charts, dado
/// el volumen de datos esperado. Genérico (no acoplado a un mazo) para
/// reutilizarse tanto en el detalle de un mazo como en la pantalla de
/// estadísticas globales.
///
/// Issue #170: con las 3 líneas a la misma altura visual se cruzaban mucho
/// y costaba leer la tendencia real. Ahora:
/// - la linea acumulada es la que mas destaca (mas gruesa + relleno debajo),
///   las de ventana corta (mas ruidosas por definicion) quedan mas finas y
///   semitransparentes para no competir con ella,
/// - la leyenda es interactiva: tocar una serie la oculta/muestra, para
///   poder aislar la tendencia sin el ruido de las otras si hace falta,
/// - selector de rango: cuantas partidas recientes se pintan (todas, o las
///   ultimas 10/20/.../100), en vez de forzar siempre el historial completo
///   (con muchas partidas el grafico se aprieta demasiado para leerse bien).
///   Es un recorte puramente de cliente sobre el timeline ya cargado, no
///   pide nada nuevo al backend.
class WinrateChart extends StatefulWidget {
  final List<dynamic> timeline;
  final String title;

  const WinrateChart({super.key, required this.timeline, this.title = 'Evolución del win-rate'});

  @override
  State<WinrateChart> createState() => _WinrateChartState();
}

class _WinrateChartState extends State<WinrateChart> {
  static const _series = [
    (key: 'cumulativeWinRate', label: 'Acumulado', color: AppColors.primaryVariant),
    (key: 'last5WinRate', label: 'Últimas 5', color: AppColors.secondary),
    (key: 'last10WinRate', label: 'Últimas 10', color: AppColors.muted),
  ];

  final Set<String> _hidden = {};

  // null = todas las partidas del timeline. Si no, muestra solo las ultimas
  // N (issue #170, ampliacion tras feedback: el filtrado por rango faltaba).
  int? _windowSize;

  void _toggle(String key) {
    setState(() {
      if (_hidden.contains(key)) {
        _hidden.remove(key);
      } else {
        _hidden.add(key);
      }
    });
  }

  double _winRateOf(List<String> results) {
    if (results.isEmpty) return 0;
    final wins = results.where((r) => r == 'win').length;
    return (wins / results.length * 1000).round() / 10;
  }

  /// Recorta al rango elegido y, si no es "Todas", recalcula
  /// cumulative/last5/last10 desde cero usando solo los resultados de ese
  /// recorte (issue #170, segunda vuelta de feedback): antes se seguian
  /// arrastrando los porcentajes calculados sobre el historial completo,
  /// asi que "Ultimas 10" mostraba el tramo final de la curva acumulada de
  /// siempre en vez de un acumulado propio empezando de cero.
  List<dynamic> get _visibleTimeline {
    final size = _windowSize;
    final full = widget.timeline;
    if (size == null) return full;

    final slice = full.length <= size ? full : full.sublist(full.length - size);

    final results = <String>[];
    return List.generate(slice.length, (i) {
      final entry = Map<String, dynamic>.from(slice[i] as Map);
      final result = entry['result'] as String;
      results.add(result);
      return {
        ...entry,
        'cumulativeWinRate': _winRateOf(results),
        'last5WinRate': _winRateOf(results.length > 5 ? results.sublist(results.length - 5) : results),
        'last10WinRate': _winRateOf(results.length > 10 ? results.sublist(results.length - 10) : results),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.timeline.length < 2) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.title, style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
            ),
            DropdownButton<int?>(
              value: _windowSize,
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textS),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (var n = 10; n <= 100; n += 10) DropdownMenuItem(value: n, child: Text('Últimas $n')),
              ],
              onChanged: (value) => setState(() => _windowSize = value),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingS),
        Wrap(
          spacing: AppSizes.spacingM,
          runSpacing: AppSizes.spacingXS,
          children: [
            for (final s in _series)
              _LegendItem(
                color: s.color,
                label: s.label,
                enabled: !_hidden.contains(s.key),
                onTap: () => _toggle(s.key),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingM),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _WinrateChartPainter(timeline: _visibleTimeline, hidden: _hidden),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _LegendItem({required this.color, required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: enabled ? color : AppColors.muted.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.spacingXS),
            Text(
              label,
              style: TextStyle(
                color: enabled ? AppColors.textSecondary : AppColors.muted.withValues(alpha: 0.5),
                fontSize: AppSizes.textXS,
                decoration: enabled ? null : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinrateChartPainter extends CustomPainter {
  final List<dynamic> timeline;
  final Set<String> hidden;

  _WinrateChartPainter({required this.timeline, required this.hidden});

  // Issue #170 (ampliacion): margen reservado a cada lado para las
  // etiquetas de porcentaje del eje Y (0/25/50/75/100%), para que no se
  // solapen con el trazado de las lineas.
  static const _axisLabelWidth = 30.0;

  /// Rect real donde se dibujan las lineas, descontando el margen de las
  /// etiquetas a izquierda y derecha.
  Rect _chartRect(Size size) =>
      Rect.fromLTRB(_axisLabelWidth, 0, size.width - _axisLabelWidth, size.height);

  List<Offset> _points(Rect chartRect, String key) {
    final n = timeline.length;
    return List.generate(n, (i) {
      final value = (timeline[i][key] as num).toDouble();
      final x = n == 1 ? chartRect.left : chartRect.left + chartRect.width * i / (n - 1);
      final y = chartRect.height * (1 - value / 100);
      return Offset(x, y);
    });
  }

  /// Lineas de ventana corta (last5/last10): mas finas y semitransparentes,
  /// para que no compitan visualmente con la acumulada.
  void _drawNoisyLine(Canvas canvas, Rect chartRect, String key, Color color) {
    final points = _points(chartRect, key);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  /// Linea acumulada: la protagonista del grafico, mas gruesa y con relleno
  /// debajo para que destaque como tendencia principal de un vistazo.
  void _drawCumulativeLine(Canvas canvas, Rect chartRect, Color color) {
    final points = _points(chartRect, 'cumulativeWinRate');

    final fillPath = Path()..moveTo(points.first.dx, chartRect.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, chartRect.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.12));

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawAxisLabel(Canvas canvas, Size size, double y, int percent) {
    final painter = TextPainter(
      text: TextSpan(
        text: '$percent%',
        style: const TextStyle(color: AppColors.muted, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelY = y - painter.height / 2;
    // Izquierda: alineado a la derecha del hueco reservado, pegado al
    // inicio del grafico. Derecha: alineado a la izquierda, pegado al final.
    painter.paint(canvas, Offset(_axisLabelWidth - painter.width - 4, labelY));
    painter.paint(canvas, Offset(size.width - _axisLabelWidth + 4, labelY));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = _chartRect(size);

    final gridPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (final fraction in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = chartRect.height * fraction;
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
      _drawAxisLabel(canvas, size, y, (100 - fraction * 100).round());
    }

    if (!hidden.contains('last10WinRate')) {
      _drawNoisyLine(canvas, chartRect, 'last10WinRate', AppColors.muted);
    }
    if (!hidden.contains('last5WinRate')) {
      _drawNoisyLine(canvas, chartRect, 'last5WinRate', AppColors.secondary);
    }
    if (!hidden.contains('cumulativeWinRate')) {
      _drawCumulativeLine(canvas, chartRect, AppColors.primaryVariant);
    }
  }

  @override
  bool shouldRepaint(covariant _WinrateChartPainter oldDelegate) =>
      oldDelegate.timeline != timeline || oldDelegate.hidden != hidden;
}
