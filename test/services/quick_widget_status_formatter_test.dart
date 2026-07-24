import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/services/quick_widget_status_formatter.dart';

void main() {
  group('QuickWidgetStatusFormatter.formatStreakLabel', () {
    test('formatea una racha de victorias', () {
      expect(QuickWidgetStatusFormatter.formatStreakLabel('win', 3), '🔥 3V seguidas');
    });

    test('formatea una racha de derrotas', () {
      expect(QuickWidgetStatusFormatter.formatStreakLabel('loss', 2), '🥶 2D seguidas');
    });

    test('usa singular cuando la racha es de 1', () {
      expect(QuickWidgetStatusFormatter.formatStreakLabel('win', 1), '🔥 1V seguida');
    });

    test('devuelve cadena vacia si no hay tipo de racha', () {
      expect(QuickWidgetStatusFormatter.formatStreakLabel(null, 0), '');
    });

    test('devuelve cadena vacia si el conteo es 0', () {
      expect(QuickWidgetStatusFormatter.formatStreakLabel('win', 0), '');
    });
  });
}
