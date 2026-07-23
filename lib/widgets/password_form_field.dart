import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// [TextFormField] para contraseñas con botón de mostrar/ocultar contenido.
///
/// Encapsula el estado de visibilidad para poder reutilizarse tanto en
/// login como en registro (contraseña + repetir contraseña) sin duplicar
/// el icono y el `setState` en cada pantalla.
class PasswordFormField extends StatefulWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.textInputAction = TextInputAction.done,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscure = true;

  void _toggleObscure() => setState(() => _obscure = !_obscure);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: AppSizes.iconNormal,
          ),
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          onPressed: _toggleObscure,
        ),
      ),
      validator: widget.validator,
    );
  }
}