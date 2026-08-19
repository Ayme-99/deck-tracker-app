import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:deck_tracker_app/screens/tournaments/tournament_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../decks/deck_list_screen.dart';
import '../stats/stats_screen.dart';
import '../tournaments/tournaments_screen.dart';
import '../tournaments/tournament_import_screen.dart';
import '../search/global_search_screen.dart';
import '../backup/backup_screen.dart';
import '../../services/accent_color_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_preference_service.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  Key _deckListKey = UniqueKey();
  Key _statsKey = UniqueKey();
  Key _tournamentsKey = UniqueKey();

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

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

  /// Selector de color de acento (issue #168): dialogo con un circulo por
  /// cada color de la paleta fija, marcando el actualmente elegido.
  Future<void> _showAccentPicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color de acento'),
        content: Wrap(
          spacing: AppSizes.spacingM,
          runSpacing: AppSizes.spacingM,
          children: AccentColorService.palette.entries.map((entry) {
            final isSelected = entry.key == AccentColorService.accentKey.value;
            return InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => Navigator.of(context).pop(entry.key),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingXS),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: AppColors.textPrimary, width: 3) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(AccentColorService.labels[entry.key]!, style: const TextStyle(fontSize: AppSizes.textXS)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) AccentColorService.setAccent(selected);
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
          IconButton(
            icon: const Icon(Icons.settings_backup_restore_outlined),
            tooltip: 'Copia de seguridad',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: AccentColorService.accentKey,
            builder: (context, accentKey, _) {
              // Muestra el color en un circulo con borde blanco en vez de
              // teñir el propio icono: en claro la barra ya usa el acento
              // de fondo, y un icono del mismo color se camuflaba del todo
              // (issue #168, cuarta ronda de feedback).
              return IconButton(
                icon: Container(
                  width: AppSizes.iconSmall,
                  height: AppSizes.iconSmall,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AccentColorService.palette[accentKey],
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
                tooltip: 'Color de acento',
                onPressed: _showAccentPicker,
              );
            },
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemePreferenceService.themeMode,
            builder: (context, mode, _) {
              return PopupMenuButton<ThemeMode>(
                icon: Icon(switch (mode) {
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                  ThemeMode.system => Icons.brightness_auto_outlined,
                }),
                tooltip: 'Tema',
                initialValue: mode,
                onSelected: ThemePreferenceService.setThemeMode,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: ThemeMode.system, child: Text('Automático (sistema)')),
                  PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
                  PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
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