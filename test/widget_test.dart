import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/main.dart';

void main() {
  testWidgets('App arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const DeckTrackerApp());
    expect(find.byType(DeckTrackerApp), findsOneWidget);
  });
}