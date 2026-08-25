import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:deck_tracker_app/screens/tournaments/tournament_form_screen.dart';
import 'package:flutter/material.dart';
import '../decks/deck_list_screen.dart';
import '../stats/stats_screen.dart';
import '../tournaments/tournaments_screen.dart';
import '../tournaments/tournament_import_screen.dart';
import '../search/global_search_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Key _deckListKey = UniqueKey();
  Key _statsKey = UniqueKey();
  Key _tournamentsKey = UniqueKey();

  Future<void> _handleCreateDeck() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DeckFormScreen()),
    );
    if (created == true) {
      setState(() => _deckListKey = UniqueKey());
    }
  }

  Future<void> _handleCreateTournament() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentFormScreen()),
    );
    if (created != null) {
      setState(() => _tournamentsKey = UniqueKey());
    }
  }

  Future<void> _handleImportTournament() async {
    final imported = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentImportScreen()),
    );
    if (imported != null) {
      setState(() => _tournamentsKey = UniqueKey());
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        _statsKey = UniqueKey(); // fuerza recarga de stats cada vez que se visita la pestaña
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Mis Mazos', 'Estadísticas', 'Torneos'];

    final screens = [
      DeckListScreen(key: _deckListKey),
      StatsScreen(key: _statsKey),
      TournamentsScreen(key: _tournamentsKey),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
          if (_currentIndex == 2)
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Importar torneo',
              onPressed: _handleImportTournament,
            ),
          // Issue #235: el menu de usuario de la #202 pasa a ser una
          // pantalla de perfil propia; los ajustes que vivian en ese menu
          // (copia de seguridad, color de acento, tema, cerrar sesion) se
          // mueven dentro de ProfileScreen, detras de un icono de engranaje.
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Perfil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _handleCreateDeck,
              icon: const Icon(Icons.add),
              label: const Text('Añadir mazo'),
            )
          : _currentIndex == 2
              ? FloatingActionButton.extended(
                  onPressed: _handleCreateTournament,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear torneo'),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.style), label: 'Mazos'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Torneos'),
        ],
      ),
    );
  }
}