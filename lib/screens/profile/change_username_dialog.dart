import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Dialogo para cambiar el nombre de usuario desde el perfil (issue #270).
/// Un unico campo, validado en cliente (longitud/caracteres) y en server
/// (unicidad), mismo patron que showChangePasswordDialog.
///
/// Devuelve el nuevo username si el cambio tuvo exito, o null si se
/// cancelo, para que quien lo llame pueda actualizar el estado local sin
/// tener que volver a pedir /auth/me.
Future<String?> showChangeUsernameDialog(BuildContext context, String currentUsername) async {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController(text: currentUsername);
  final authService = AuthService();
  final l10n = AppLocalizations.of(context);

  bool isLoading = false;
  String? errorMessage;
  String? newUsername;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        Future<void> handleSubmit() async {
          if (!formKey.currentState!.validate()) return;
          setDialogState(() {
            isLoading = true;
            errorMessage = null;
          });
          try {
            final trimmed = usernameController.text.trim();
            await authService.changeUsername(trimmed);
            if (!context.mounted) return;
            newUsername = trimmed;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.usernameChangedSuccess)),
            );
          } catch (e) {
            setDialogState(() {
              errorMessage = e.toString().replaceFirst('Exception: ', '');
              isLoading = false;
            });
          }
        }

        return AlertDialog(
          title: Text(l10n.changeUsernameTitle),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: usernameController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => handleSubmit(),
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
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSizes.spacingM),
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.cancelAction),
            ),
            FilledButton(
              onPressed: isLoading ? null : handleSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: AppSizes.spinnerSmall,
                      width: AppSizes.spinnerSmall,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.saveAction),
            ),
          ],
        );
      },
    ),
  );

  usernameController.dispose();
  return newUsername;
}