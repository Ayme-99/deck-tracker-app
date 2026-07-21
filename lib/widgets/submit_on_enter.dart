import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Envuelve cualquier formulario/dialogo para que la tecla Enter (o el
/// Enter del teclado numerico) dispare la accion principal, sin importar
/// en que campo de texto este el foco -- evita tener que encadenar
/// FocusNode + onFieldSubmitted campo a campo en cada pantalla (issue #37).
///
/// Uso:
/// ```dart
/// SubmitOnEnter(
///   onSubmit: _handleLogin, // tu funcion de "Aceptar"/"Guardar"/etc.
///   child: Form(...),
/// )
/// ```
///
/// Si el botón principal puede estar deshabilitado (ej. mientras se
/// envia, o si el formulario no es valido todavia), pasa `enabled: false`
/// en esos casos para que Enter tampoco haga nada, igual que el boton.
class SubmitOnEnter extends StatelessWidget {
  final VoidCallback onSubmit;
  final Widget child;
  final bool enabled;

  const SubmitOnEnter({
    super.key,
    required this.onSubmit,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (enabled) onSubmit();
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (enabled) onSubmit();
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}