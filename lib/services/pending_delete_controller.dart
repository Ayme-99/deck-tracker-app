import 'dart:async';
import 'package:flutter/material.dart';

/// Borrado con "deshacer" (issue #128), reutilizable en cualquier pantalla
/// con una lista de items borrables. La llamada DELETE real se retrasa:
///
/// 1. Al pedir el borrado, el item se quita de la lista en memoria al
///    instante (feedback visual) y se muestra un SnackBar con accion
///    "Deshacer" durante [duration].
/// 2. Si se pulsa "Deshacer", se cancela el borrado: nunca se llega a
///    llamar al backend, y el item se reinserta en la lista.
/// 3. Si el SnackBar expira sin pulsar deshacer, se dispara el DELETE real.
/// 4. Si la pantalla se cierra con un borrado pendiente, [dispose] lo
///    dispara de inmediato en vez de perderlo en silencio.
///
/// Cada pantalla instancia uno con sus propios callbacks; el controller no
/// sabe nada de Deck/Match/Tournament en concreto.
class PendingDeleteController<T> {
  final Future<void> Function(T item) onDelete;
  final void Function(T item) onRemoveLocally;
  final void Function(T item) onRestoreLocally;
  final String Function(T item) buildMessage;
  final Duration duration;

  PendingDeleteController({
    required this.onDelete,
    required this.onRemoveLocally,
    required this.onRestoreLocally,
    required this.buildMessage,
    this.duration = const Duration(seconds: 4),
  });

  final Map<T, Timer> _pending = {};

  /// Items con un borrado todavia pendiente (SnackBar de deshacer abierto).
  /// Util para filtrar un reload desde el servidor mientras hay un borrado
  /// en curso, y que no "reaparezca" un item que ya se quito localmente.
  Set<T> get pendingItems => _pending.keys.toSet();

  /// Pide borrar [item]: lo quita de la lista ya mismo y muestra el
  /// SnackBar de deshacer. No hace falta `await` -- el borrado real ocurre
  /// mas tarde, de forma asincrona.
  void requestDelete(BuildContext context, T item) {
    // Por si ya habia un borrado pendiente de este mismo item (doble tap),
    // se cancela el anterior antes de empezar uno nuevo.
    _pending.remove(item)?.cancel();

    onRemoveLocally(item);

    _pending[item] = Timer(duration, () {
      _pending.remove(item);
      onDelete(item);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(buildMessage(item)),
          duration: duration,
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              final timer = _pending.remove(item);
              if (timer == null) return; // ya se disparo el borrado real, tarde para deshacer
              timer.cancel();
              onRestoreLocally(item);
            },
          ),
        ),
      );
  }

  /// Dispara de inmediato cualquier borrado pendiente (fire-and-forget) --
  /// llamar desde `State.dispose()` para no perder un borrado si el
  /// usuario sale de la pantalla antes de que expire el SnackBar.
  void dispose() {
    for (final entry in _pending.entries.toList()) {
      entry.value.cancel();
      onDelete(entry.key);
    }
    _pending.clear();
  }
}
