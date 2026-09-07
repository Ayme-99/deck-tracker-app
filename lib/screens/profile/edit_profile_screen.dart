import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Pantalla de edicion de perfil (issue #270 y futuras: #269 foto, #274
/// email, #271 Google, #275 eliminar cuenta...). Punto unico de entrada
/// para todo lo que sea "editar mi cuenta", en vez de ir esparciendo
/// dialogos/iconos sueltos por ProfileScreen a medida que crece el alcance.
///
/// Devuelve al hacer pop un Map<String, dynamic> con los campos que
/// cambiaron realmente (hoy como mucho {'username': nuevoValor}), para que
/// ProfileScreen actualice su estado local sin recargar todo el perfil. Si
/// no hubo ningun cambio guardado, devuelve null.
class EditProfileScreen extends StatefulWidget {
  final String currentUsername;

  const EditProfileScreen({super.key, required this.currentUsername});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late final TextEditingController _usernameController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedUsername = _usernameController.text.trim();
    final changes = <String, dynamic>{};

    // Solo se llama al endpoint si el campo realmente cambio -- evita una
    // llamada de red (y el rechazo por "unico pero ya es tuyo" que el
    // server ya maneja, pero mejor no depender de eso) cuando el usuario
    // entra, no toca nada y le da a Guardar.
    if (trimmedUsername != widget.currentUsername) {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });
      try {
        await _authService.changeUsername(trimmedUsername);
        changes['username'] = trimmedUsername;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
        return;
      }
    }

    if (!mounted) return;

    if (changes.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop(changes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.usernameChangedSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.newUsernameLabel,
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return l10n.usernameRequired;
                  if (trimmed.length < 3 || trimmed.length > 20) {
                    return l10n.usernameLengthError;
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
                    return l10n.usernameInvalidCharsError;
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSizes.spacingM),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSizes.spacingL),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          height: AppSizes.spinnerSmall,
                          width: AppSizes.spinnerSmall,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.saveAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}