import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/auth_service.dart';
import '../../widgets/password_form_field.dart';
import '../../l10n/app_localizations.dart';

/// Confirmacion de eliminacion de cuenta (issue #275). Pantalla dedicada,
/// no un AlertDialog como el resto de acciones de EditProfileScreen -- es
/// la accion mas destructiva de todas (borrado en cascada e irreversible),
/// asi que pide la contraseña actual como paso de friccion deliberada
/// antes de proceder, igual que ChangePasswordDialog exige la actual para
/// poner una nueva.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _passwordController = TextEditingController();

  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _authService.deleteAccount(_passwordController.text);
      if (!mounted) return;
      // Issue #234: mismo motivo que en logout -- context.go en vez de
      // Navigator.pop en cadena, para no dejar el resto del stack (perfil,
      // editar perfil...) apilado por debajo de la pantalla de login.
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_outlined, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: AppSizes.spacingS),
                      Expanded(child: Text(l10n.deleteAccountWarning)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingL),
              PasswordFormField(
                controller: _passwordController,
                labelText: l10n.currentPasswordLabel,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.currentPasswordRequired;
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
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                  onPressed: _isDeleting ? null : _handleDelete,
                  child: _isDeleting
                      ? const SizedBox(
                          height: AppSizes.spinnerSmall,
                          width: AppSizes.spinnerSmall,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.deleteAccountAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}