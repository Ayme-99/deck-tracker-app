import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/auth_service.dart';
import '../../widgets/password_form_field.dart';
import '../../l10n/app_localizations.dart';

/// Dialogo para cambiar la contraseña desde el perfil (issue #273).
/// Pide la contraseña actual (la valida el server) y la nueva dos veces.
///
/// Es un StatefulWidget de verdad (no una funcion con StatefulBuilder +
/// TextEditingController creados/destruidos a mano): al hacer dispose()
/// manual de los controllers justo despues del await de showDialog(), la
/// animacion de cierre del dialogo todavia no habia terminado de desmontar
/// el arbol -- Flutter intentaba seguir pintando los TextFormField con
/// controllers ya destruidos ("A TextEditingController was used after
/// being disposed"), lo que en cascada disparaba un assertion failure del
/// framework. Con un StatefulWidget, dispose() lo llama Flutter en el
/// momento correcto (cuando el Element se desmonta de verdad).
Future<void> showChangePasswordDialog(BuildContext parentContext) async {
  final l10n = AppLocalizations.of(parentContext);
  final success = await showDialog<bool>(
    context: parentContext,
    builder: (context) => const _ChangePasswordDialog(),
  );

  if (success == true && parentContext.mounted) {
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text(l10n.passwordChangedSuccess)),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context);
    final current = _currentController.text;
    final newPassword = _newController.text;
    final confirm = _confirmController.text;

    String? validationError;
    if (current.isEmpty) {
      validationError = l10n.currentPasswordRequired;
    } else if (newPassword.length < 6) {
      validationError = l10n.registerPasswordMinLength;
    } else if (confirm.isEmpty) {
      validationError = l10n.registerConfirmPasswordRequired;
    } else if (confirm != newPassword) {
      validationError = l10n.registerPasswordsDontMatch;
    }
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.changePassword(current, newPassword);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.changePasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PasswordFormField(
              controller: _currentController,
              labelText: l10n.currentPasswordLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.spacingM),
            PasswordFormField(
              controller: _newController,
              labelText: l10n.newPasswordLabel,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.spacingM),
            PasswordFormField(
              controller: _confirmController,
              labelText: l10n.registerConfirmPasswordLabel,
              textInputAction: TextInputAction.done,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSizes.spacingM),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: AppSizes.spinnerSmall,
                  width: AppSizes.spinnerSmall,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.saveAction),
        ),
      ],
    );
  }
}
