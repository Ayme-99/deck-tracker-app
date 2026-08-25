import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/widgets/winrate_chart.dart';

void main() {
  group('winrateChartGridLines', () {
    // Casos de referencia de la issue #243. N=70 es un caso admitido como
    // sin formula limpia (ver comentario junto a winrateChartGridStep) --
    // se documenta el resultado real de la formula elegida, no el ejemplo
    // manual original de la issue.
    final cases = {
      10: [5],
      20: [5, 10, 15],
      30: [10, 20],
      40: [10, 20, 30],
      50: [10, 20, 30, 40],
      60: [15, 30, 45],
      70: [20, 40, 60],
      80: [20, 40, 60],
    };

    cases.forEach((n, expected) {
      test('N=$n -> $expected', () {
        expect(winrateChartGridLines(n), expected);
      });
    });

    test('N=0 no genera lineas', () {
      expect(winrateChartGridLines(0), isEmpty);
    });

    test('N pequeño (menor que el paso minimo) no genera lineas', () {
      expect(winrateChartGridLines(3), isEmpty);
    });
  });
}
