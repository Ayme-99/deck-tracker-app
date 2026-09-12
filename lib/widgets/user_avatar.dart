import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';

/// Avatar de usuario reutilizable (issue #269): unico punto donde se decide
/// como convertir el avatarBase64 (data URI completa, tal como la guarda y
/// devuelve el server) en una imagen, y cual es el fallback cuando no hay
/// foto. Cualquier pantalla que necesite mostrar el avatar de un usuario
/// (perfil propio, lista de amigos, etc.) usa este widget en vez de
/// reimplementar el decode + CircleAvatar cada vez.
class UserAvatar extends StatelessWidget {
  final String? avatarBase64;
  final double radius;

  const UserAvatar({
    super.key,
    required this.avatarBase64,
    this.radius = AppSizes.iconHuge / 2,
  });

  @override
  Widget build(BuildContext context) {
    final base64Value = avatarBase64;
    if (base64Value == null || base64Value.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.person, size: radius),
      );
    }

    try {
      final base64Part = base64Value.split(',').last;
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(base64Decode(base64Part)),
      );
    } catch (_) {
      // Dato corrupto o formato inesperado -- fallback silencioso al icono
      // generico en vez de tirar la pantalla entera abajo.
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.person, size: radius),
      );
    }
  }
}