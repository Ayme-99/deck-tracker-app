import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/auth_service.dart';
import '../../widgets/submit_on_enter.dart';
import '../../widgets/password_form_field.dart';
import '../../l10n/app_localizations.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  // Issue #96: si se llega aqui por caducidad de sesion (JWT expirado,
  // ver ApiService._handleSessionExpired), se muestra un mensaje especifico
  // en vez de dejar el formulario en blanco sin explicacion.
  final bool sessionExpired;

  const LoginScreen({super.key, this.sessionExpired = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isSlow = false;
  Timer? _slowTimer;
  String? _errorMessage;
  bool _showSessionExpired = false;

  @override
  void initState() {
    super.initState();
    _showSessionExpired = widget.sessionExpired;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isSlow = false;
      _errorMessage = null;
    });

    _slowTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isSlow = true);
    });

    try {
      await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      context.go('/decks');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _slowTimer?.cancel();
      if (mounted) setState(() { _isLoading = false; _isSlow = false; });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_showSessionExpired) {
      _showSessionExpired = false;
      _errorMessage = l10n.loginSessionExpired;
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingL),
            child: SubmitOnEnter(
              onSubmit: _handleLogin,
              enabled: !_isLoading,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.style, size: AppSizes.iconHuge),
                    const SizedBox(height: AppSizes.spacingM),
                    Text(
                      l10n.appTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spacingXL),

                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.usernameLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.loginUsernameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.spacingM),

                    PasswordFormField(
                      controller: _passwordController,
                      labelText: l10n.passwordLabel,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.loginPasswordRequired;
                        }
                        return null;
                      },
                  ),
                  const SizedBox(height: AppSizes.spacingL),

                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.loginSubmitButton),
                  ),
                  if (_isSlow) ...[
                    const SizedBox(height: AppSizes.spacingS),
                    Text(
                      l10n.loginServerWakingUp,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textS),
                    ),
                  ],
                  const SizedBox(height: AppSizes.spacingSM),

                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(l10n.loginRegisterLink),
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}