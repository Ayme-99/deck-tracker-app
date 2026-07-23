import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../services/deck_service.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../../widgets/sprite_avatar_group.dart';
import 'register_match_screen.dart';

/// Selector de mazo del widget de acceso rápido (issue #10): al tocar el
/// widget en la pantalla de inicio del móvil, la app abre directamente
/// aquí (sin pasar por Mazos > detalle) para elegir con qué mazo se va a
/// registrar la partida, y de ahí entra directo a [RegisterMatchScreen].
class QuickRegisterDeckPickerScreen extends StatefulWidget {
  const QuickRegisterDeckPickerScreen({super.key});

  @override
  State<QuickRegisterDeckPickerScreen> createState() => _QuickRegisterDeckPickerScreenState();
}

class _QuickRegisterDeckPickerScreenState extends State<QuickRegisterDeckPickerScreen> {
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
      if (!mounted) return;
      setState(() {
        // Mismo orden por actividad reciente que la lista de mazos (issue
        // #98): el mazo con el que jugaste hace menos aparece primero.
        _decks = [...decks]..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDeck(Deck deck) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegisterMatchScreen(deck: deck)),
    );
    // Tras registrar (o cancelar), vuelve al flujo normal de la app en vez
    // de quedarse en este selector de un solo uso.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar partida')),
      body: _isLoading
          ? const SlowLoadingIndicator()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error al cargar mazos: $_errorMessage', textAlign: TextAlign.center),
                        const SizedBox(height: AppSizes.spacingM),
                        FilledButton(onPressed: _loadDecks, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _decks.isEmpty
                  ? Center(
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
                              'Crea un mazo desde la app para poder registrar partidas',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.spacingM),
                      itemCount: _decks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.spacingS),
                      itemBuilder: (context, index) {
                        final deck = _decks[index];
                        return Card(
                          child: ListTile(
                            leading: SpriteAvatarGroup(
                              sprite1: deck.sprite1,
                              sprite2: deck.sprite2,
                              size: AppSizes.iconNormal,
                            ),
                            title: Text(deck.name),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                            onTap: () => _selectDeck(deck),
                          ),
                        );
                      },
                    ),
    );
  }
}
