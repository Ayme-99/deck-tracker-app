import 'package:flutter/material.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Mazos')),
      body: const Center(
        child: Text('Aquí irá el listado de mazos'),
      ),
    );
  }
}