import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';

class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  final _deckService = DeckService();

  List<Deck> _decks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final decks = await _deckService.getDecks();
      setState(() {
        _decks = decks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error al cargar mazos: $_errorMessage',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadDecks,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_decks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.style_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Todavía no tienes mazos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea tu primer mazo para empezar a registrar partidas',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // Próximo paso: pantalla de creación de mazo
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear mazo'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDecks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _decks.length,
        itemBuilder: (context, index) {
          final deck = _decks[index];
          final totalMatches = deck.wins + deck.losses;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                deck.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${deck.format} · $totalMatches partidas'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Próximo paso: pantalla de detalle del mazo
              },
            ),
          );
        },
      ),
    );
  }
}