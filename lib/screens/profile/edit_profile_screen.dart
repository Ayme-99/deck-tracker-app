import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/user_avatar.dart';

/// Pantalla de edicion de perfil (issue #270, #269 y futuras: #274 email,
/// #271 Google, #275 eliminar cuenta...). Punto unico de entrada para todo
/// lo que sea "editar mi cuenta", en vez de ir esparciendo dialogos/iconos
/// sueltos por ProfileScreen a medida que crece el alcance.
///
/// Devuelve al hacer pop un Map<String, dynamic> con los campos que
/// cambiaron realmente (ej. {'username': ...} y/o {'avatarBase64': ...}),
/// para que ProfileScreen actualice su estado local sin recargar todo el
/// perfil. Si no hubo ningun cambio guardado, devuelve null.
class EditProfileScreen extends StatefulWidget {
  final String currentUsername;
  final String? currentAvatarBase64;

  const EditProfileScreen({
    super.key,
    required this.currentUsername,
    this.currentAvatarBase64,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  late final TextEditingController _usernameController;

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
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // Issue #269: redimension y compresion ya en origen via maxWidth/
  // maxHeight/imageQuality -- evita tener que anadir un paquete aparte de
  // procesado de imagenes solo para esto. 512px de lado y calidad 80 dan un
  // JPEG de sobra pequeno para un avatar (tipicamente bastante por debajo
  // del limite de 500KB que valida el server).
  Future<void> _pickAvatar() async {
    final l10n = AppLocalizations.of(context);
    try {
      final picked = await _imagePicker.pickImage(
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
    final changes = <String, dynamic>{};

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Solo se llama a cada endpoint si el campo correspondiente realmente
    // cambio -- evita llamadas de red innecesarias cuando el usuario entra,
    // no toca nada (o solo una de las dos cosas) y le da a Guardar.
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