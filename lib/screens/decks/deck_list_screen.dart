import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:deck_tracker_app/widgets/sprite_avatar_group.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';
import '../services/stats_service.dart';
import 'deck_detail_screen.dart';


class DeckListScreen extends StatefulWidget {
  const DeckListScreen({super.key});

  @override
  State<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends State<DeckListScreen> {
  final _deckService = DeckService();
  final _statsService = StatsService();

  List<Deck> _decks = [];
  Map<String, int> _matchCounts = {};
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

      // Trae el numero real de partidas de cada mazo en paralelo
      final overviews = await Future.wait(
        decks.map((deck) => _statsService.getDeckOverview(deck.id)),
      );

      final counts = <String, int>{};
      for (var i = 0; i < decks.length; i++) {
        counts[decks[i].id] = overviews[i]['totalMatches'] ?? 0;
      }

      setState(() {
        _decks = decks;
        _matchCounts = counts;
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
          padding: const EdgeInsets.all(AppSizes.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error al cargar mazos: $_errorMessage', textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.spacingM),
              FilledButton.icon(
                onPressed: () async {
                  final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const DeckFormScreen()),
                  );
                  if (created == true) _loadDecks();
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear mazo'),
              ),
            ],
          ),
        ),
      );
    }

    if (_decks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.style_outlined, size: AppSizes.iconHuge, color: AppColors.muted),
              const SizedBox(height: AppSizes.spacingM),
              const Text(
                'Todavía no tienes mazos',
                style: TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.spacingS),
              const Text(
                'Crea tu primer mazo para empezar a registrar partidas',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDecks,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        itemCount: _decks.length,
        itemBuilder: (context, index) {
          final deck = _decks[index];
          final totalMatches = _matchCounts[deck.id] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              minLeadingWidth: 0,
              horizontalTitleGap: AppSizes.spacingS,
              leading: SpriteAvatarGroup(sprite1: deck.sprite1, sprite2: deck.sprite2),
              title: Text(
                deck.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${deck.format} · $totalMatches partidas'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)),
                );
                _loadDecks(); // refresca contadores al volver, por si se añadieron partidas
              },
            ),
          );
        },
      ),
    );
  }
}