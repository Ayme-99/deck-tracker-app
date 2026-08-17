import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/widgets/deck_shuffle_indicator.dart';

void main() {
  testWidgets('DeckShuffleIndicator se pinta y repite la animacion sin errores', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: DeckShuffleIndicator()))),
    );

    expect(find.byType(DeckShuffleIndicator), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Avanza varios ciclos completos de la animacion (dura 1400ms) para
    // confirmar que el bucle (AnimationController.repeat()) no lanza excepciones.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 1500));

    expect(tester.takeException(), isNull);
  });

  testWidgets('se puede desmontar sin fugas de recursos (dispose del AnimationController)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: DeckShuffleIndicator()))),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

    expect(tester.takeException(), isNull);
  });
}
