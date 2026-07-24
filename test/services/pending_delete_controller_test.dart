import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deck_tracker_app/services/pending_delete_controller.dart';

/// Host minimo con un boton para disparar requestDelete y otro para
/// disparar la accion "Deshacer" del ultimo SnackBar mostrado (el propio
/// SnackBarAction no es facil de "tocar" en un test sin buscar su texto,
/// asi que usamos find.text('Deshacer') directamente sobre el SnackBar).
class _Harness extends StatefulWidget {
  final PendingDeleteController<String> controller;
  const _Harness({required this.controller});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => widget.controller.requestDelete(context, 'item-1'),
            child: const Text('Borrar'),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('si se pulsa Deshacer antes de que expire, no se llama a onDelete', (tester) async {
    var deleted = false;
    var removedLocally = false;
    var restoredLocally = false;

    final controller = PendingDeleteController<String>(
      duration: const Duration(seconds: 4),
      onDelete: (item) async => deleted = true,
      onRemoveLocally: (item) => removedLocally = true,
      onRestoreLocally: (item) => restoredLocally = true,
      buildMessage: (item) => 'Elemento "$item" eliminado',
    );

    await tester.pumpWidget(_Harness(controller: controller));
    await tester.tap(find.text('Borrar'));
    await tester.pump();

    expect(removedLocally, isTrue);
    expect(find.text('Elemento "item-1" eliminado'), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pump();

    expect(restoredLocally, isTrue);

    // Deja pasar el tiempo suficiente para confirmar que, tras deshacer,
    // el borrado real ya no se dispara.
    await tester.pump(const Duration(seconds: 5));
    expect(deleted, isFalse);
  });

  testWidgets('si expira el tiempo sin deshacer, se dispara el borrado real', (tester) async {
    var deleted = false;

    final controller = PendingDeleteController<String>(
      duration: const Duration(seconds: 4),
      onDelete: (item) async => deleted = true,
      onRemoveLocally: (item) {},
      onRestoreLocally: (item) {},
      buildMessage: (item) => 'Elemento "$item" eliminado',
    );

    await tester.pumpWidget(_Harness(controller: controller));
    await tester.tap(find.text('Borrar'));
    await tester.pump();

    expect(deleted, isFalse);

    await tester.pump(const Duration(seconds: 5));
    expect(deleted, isTrue);
  });

  testWidgets('dispose dispara de inmediato cualquier borrado pendiente', (tester) async {
    var deleted = false;

    final controller = PendingDeleteController<String>(
      duration: const Duration(seconds: 4),
      onDelete: (item) async => deleted = true,
      onRemoveLocally: (item) {},
      onRestoreLocally: (item) {},
      buildMessage: (item) => 'Elemento "$item" eliminado',
    );

    await tester.pumpWidget(_Harness(controller: controller));
    await tester.tap(find.text('Borrar'));
    await tester.pump();

    expect(deleted, isFalse);
    controller.dispose();
    expect(deleted, isTrue);
  });

  testWidgets('pendingItems refleja los borrados en curso', (tester) async {
    final controller = PendingDeleteController<String>(
      duration: const Duration(seconds: 4),
      onDelete: (item) async {},
      onRemoveLocally: (item) {},
      onRestoreLocally: (item) {},
      buildMessage: (item) => 'Elemento "$item" eliminado',
    );

    await tester.pumpWidget(_Harness(controller: controller));
    expect(controller.pendingItems, isEmpty);

    await tester.tap(find.text('Borrar'));
    await tester.pump();

    expect(controller.pendingItems, {'item-1'});

    controller.dispose();
    expect(controller.pendingItems, isEmpty);
  });
}
