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
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  // Issue #202: nombre de usuario mostrado en el menu de usuario. Si falla
  // (ej. sin red al arrancar), simplemente no se muestra -- no es critico
  // para el resto de la pantalla.
  Future<void> _loadUsername() async {
    try {
      final me = await _authService.getMe();
      if (!mounted) return;
      setState(() => _username = me['username'] as String?);
    } catch (_) {
      // sin username no pasa nada, el menu funciona igual
    }
  }

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

  /// Selector de tema (issue #202): mismo patron de dialogo que el color de
  /// acento, para que ambos vivan como entradas del menu de usuario en vez
  /// de icon buttons sueltos.
  Future<void> _showThemePicker() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Tema'),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(mode),
              child: Row(
                children: [
                  Icon(switch (mode) {
                    ThemeMode.system => Icons.brightness_auto_outlined,
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                  }),
                  const SizedBox(width: AppSizes.spacingM),
                  Text(switch (mode) {
                    ThemeMode.system => 'Automático (sistema)',
                    ThemeMode.light => 'Claro',
                    ThemeMode.dark => 'Oscuro',
                  }),
                ],
              ),
            ),
        ],
      ),
    );

    if (selected != null) ThemePreferenceService.setThemeMode(selected);
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
          // Issue #202: copia de seguridad, color de acento, tema y cerrar
          // sesion vivian como icon buttons sueltos que se iban acumulando
          // en la AppBar segun se añadian funciones -- se agrupan en un
          // unico menu de usuario (primer paso hacia una futura pantalla de
          // perfil/ajustes).
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Usuario',
            itemBuilder: (context) => [
              if (_username != null) ...[
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(_username!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.settings_backup_restore_outlined),
                  title: Text('Copia de seguridad'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'accent',
                child: ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Color de acento'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'theme',
                child: ListTile(
                  leading: Icon(Icons.brightness_6_outlined),
                  title: Text('Tema'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'backup':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  );
                case 'accent':
                  _showAccentPicker();
                case 'theme':
                  _showThemePicker();
                case 'logout':
                  _handleLogout();
              }
            },
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