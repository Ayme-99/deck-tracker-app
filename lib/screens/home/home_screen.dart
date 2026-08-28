import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:deck_tracker_app/screens/tournaments/tournament_form_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/update_check_service.dart';
import '../tournaments/tournament_import_screen.dart';
import '../search/global_search_screen.dart';
import '../profile/profile_screen.dart';

/// Shell de las 3 pestañas principales (issue #238: cada una vive en su
/// propia ruta con URL real -- /decks, /stats, /tournaments -- via
/// StatefulShellRoute, que mantiene el estado de cada pestaña vivo al
/// cambiar entre ellas, igual que hacia antes el IndexedStack manual).
class HomeScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeScreen({super.key, required this.navigationShell});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

// Reemplaza el metodo _checkForUpdate existente en home_screen.dart por
// este (issue #248), y añade el import:
//
// import '../update/update_dialog.dart';
//
// El resto del archivo (HomeScreen, _handleCreateDeck, build, etc.) no
// cambia.

Future<void> _checkForUpdate() async {
  if (kIsWeb) return;
  final update = await UpdateCheckService().checkForUpdate();
  if (update == null || !mounted) return;

  showDialog(
    context: context,
    builder: (context) => UpdateDialog(update: update),
  );
}

  Future<void> _handleCreateDeck() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DeckFormScreen()),
    );
    if (created == true) {
      // initialLocation: true resetea la pestaña a su ruta inicial,
      // forzando su recarga -- mismo efecto que antes tenia el UniqueKey.
      widget.navigationShell.goBranch(0, initialLocation: true);
    }
  }

  Future<void> _handleCreateTournament() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentFormScreen()),
    );
    if (created != null) {
      widget.navigationShell.goBranch(2, initialLocation: true);
    }
  }

  Future<void> _handleImportTournament() async {
    final imported = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentImportScreen()),
    );
    if (imported != null) {
      widget.navigationShell.goBranch(2, initialLocation: true);
    }
  }

  void _onTabSelected(int index) {
    // La pestaña de Stats siempre se recarga al seleccionarla (mismo
    // comportamiento previo al UniqueKey); Mazos/Torneos preservan su
    // estado al volver a ellas.
    widget.navigationShell.goBranch(index, initialLocation: index == 1);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final titles = ['Mis Mazos', 'Estadísticas', 'Torneos'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
          if (currentIndex == 2)
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
      body: widget.navigationShell,
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _handleCreateDeck,
              icon: const Icon(Icons.add),
              label: const Text('Añadir mazo'),
            )
          : currentIndex == 2
              ? FloatingActionButton.extended(
                  onPressed: _handleCreateTournament,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear torneo'),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
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