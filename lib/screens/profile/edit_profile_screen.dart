import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_avatar.dart';
import '../../l10n/app_localizations.dart';

/// Pantalla de edicion de perfil (issue #270, #269, #274 y futuras: #271
/// Google, #275 eliminar cuenta...). Punto unico de entrada para todo lo
/// que sea "editar mi cuenta", en vez de ir esparciendo dialogos/iconos
/// sueltos por ProfileScreen a medida que crece el alcance.
///
/// Devuelve al hacer pop un Map<String, dynamic> con los campos que
/// cambiaron realmente (ej. {'username': ...}, {'avatarBase64': ...} y/o
/// {'email': ..., 'emailVerified': false}), para que ProfileScreen
/// actualice su estado local sin recargar todo el perfil. Si no hubo
/// ningun cambio guardado, devuelve null.
class EditProfileScreen extends StatefulWidget {
  final String currentUsername;
  final String? currentAvatarBase64;
  final String? currentEmail;

  const EditProfileScreen({
    super.key,
    required this.currentUsername,
    this.currentAvatarBase64,
    this.currentEmail,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

  bool _isSaving = false;
  String? _errorMessage;

  // Bytes de la nueva imagen elegida (si el usuario cambio la foto) y su
  // data URI ya lista para el server. Mientras no se guarde, se muestra la
  // previsualizacion en memoria en vez de la que ya hay en el perfil.
  Uint8List? _pendingAvatarBytes;
  String? _pendingAvatarDataUri;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _emailController = TextEditingController(text: widget.currentEmail ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context);
    try {
      // Issue #269: en web, image_picker_for_web tiene un bug conocido al
      // redimensionar via maxWidth/maxHeight/imageQuality (el blob URL de
      // la imagen puede fallar a cargar durante el resize en <canvas>,
      // "Couldn't load blob from this url"). En web se pide la imagen sin
      // redimensionar y se confia en la validacion de tamano del server;
      // en nativo (donde el resize si es fiable) se mantiene el
      // redimensionado en origen para no subir base64 innecesariamente
      // grandes.
      final picked = kIsWeb
          ? await _imagePicker.pickImage(source: ImageSource.gallery)
          : await _imagePicker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 512,
              maxHeight: 512,
              imageQuality: 80,
            );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final mimeType = _mimeTypeFor(picked.name);

      setState(() {
        _pendingAvatarBytes = bytes;
        _pendingAvatarDataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.avatarPickError(e.toString().replaceFirst('Exception: ', '')))),
      );
    }
  }

  String _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedUsername = _usernameController.text.trim();
    final trimmedEmail = _emailController.text.trim();
    final changes = <String, dynamic>{};

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Solo se llama a cada endpoint si el campo correspondiente realmente
    // cambio -- evita llamadas de red innecesarias cuando el usuario entra,
    // no toca nada (o solo alguno de los campos) y le da a Guardar.
    if (trimmedUsername != widget.currentUsername) {
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

    if (_pendingAvatarDataUri != null) {
      try {
        await _authService.changeAvatar(_pendingAvatarDataUri!);
        changes['avatarBase64'] = _pendingAvatarDataUri;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSaving = false;
        });
        return;
      }
    }

    if (trimmedEmail.isNotEmpty && trimmedEmail != (widget.currentEmail ?? '')) {
      try {
        final response = await _authService.changeEmail(trimmedEmail);
        changes['email'] = response['email'];
        changes['emailVerified'] = response['emailVerified'];
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
      SnackBar(content: Text(l10n.profileUpdatedSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasExistingEmail = widget.currentEmail != null && widget.currentEmail!.isNotEmpty;

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
              Center(
                child: GestureDetector(
                  onTap: _isSaving ? null : _pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _pendingAvatarBytes != null
                          ? CircleAvatar(
                              radius: AppSizes.iconHuge / 2,
                              backgroundImage: MemoryImage(_pendingAvatarBytes!),
                            )
                          : UserAvatar(
                              avatarBase64: widget.currentAvatarBase64,
                              radius: AppSizes.iconHuge / 2,
                            ),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.spacingXS),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: AppSizes.iconSmall, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spacingL),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: AppSizes.spacingM),
              TextFormField(
                controller: _emailController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  // Issue #274: cuentas anteriores a la #268 pueden no
                  // tener email todavia -- mismo campo/endpoint sirve para
                  // anadirlo por primera vez o cambiarlo, solo cambia el
                  // texto para que quede claro que accion se esta haciendo.
                  labelText: hasExistingEmail ? l10n.changeEmailLabel : l10n.addEmailLabel,
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  // El email es opcional: una cuenta sin email puede seguir
                  // sin tenerlo si el usuario deja el campo vacio.
                  if (trimmed.isEmpty) return null;
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
                    return l10n.emailInvalid;
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