import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/auth_service.dart';
import '../../widgets/password_form_field.dart';
import '../../l10n/app_localizations.dart';

/// Dialogo para cambiar la contraseña desde el perfil (issue #273).
/// Pide la contraseña actual (la valida el server) y la nueva dos veces.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  final authService = AuthService();
  final l10n = AppLocalizations.of(context);

  bool isLoading = false;
  String? errorMessage;

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
            await authService.changePassword(currentController.text, newController.text);
            if (!context.mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.passwordChangedSuccess)),
            );
          } catch (e) {
            setDialogState(() {
              errorMessage = e.toString().replaceFirst('Exception: ', '');
              isLoading = false;
            });
          }
        }

        return AlertDialog(
          title: Text(l10n.changePasswordTitle),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PasswordFormField(
                    controller: currentController,
                    labelText: l10n.currentPasswordLabel,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l10n.currentPasswordRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  PasswordFormField(
                    controller: newController,
                    labelText: l10n.newPasswordLabel,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.length < 6) return l10n.registerPasswordMinLength;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  PasswordFormField(
                    controller: confirmController,
                    labelText: l10n.registerConfirmPasswordLabel,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l10n.registerConfirmPasswordRequired;
                      if (value != newController.text) return l10n.registerPasswordsDontMatch;
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

  currentController.dispose();
  newController.dispose();
  confirmController.dispose();
}
