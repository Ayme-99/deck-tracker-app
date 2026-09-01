import 'package:deck_tracker_app/screens/decks/deck_form_screen.dart';
import 'package:deck_tracker_app/screens/tournaments/tournament_form_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/tab_refresh_signals.dart';
import '../../services/update_check_service.dart';
import '../tournaments/tournament_import_screen.dart';
import '../search/global_search_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/update/update_dialog.dart';
import '../../l10n/app_localizations.dart';

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

  // Issue #233/#248: aviso de nueva version disponible. En web no tiene
  // sentido "instalar" nada -- se omite la comprobacion.
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
      // Ver tab_refresh_signals.dart: goBranch(index, initialLocation: true)
      // no basta por si solo (no remonta el widget si la rama ya esta en su
      // ubicacion inicial, que es el caso normal aqui).
      deckListRefreshSignal.value++;
    }
  }

  Future<void> _handleCreateTournament() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentFormScreen()),
    );
    if (created != null) {
      tournamentsListRefreshSignal.value++;
    }
  }

  Future<void> _handleImportTournament() async {
    final imported = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TournamentImportScreen()),
    );
    if (imported != null) {
      tournamentsListRefreshSignal.value++;
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
    final l10n = AppLocalizations.of(context);
    final currentIndex = widget.navigationShell.currentIndex;
    final titles = [l10n.homeTitleDecks, l10n.homeTitleStats, l10n.homeTitleTournaments];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.searchTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
            ),
          ),
          if (currentIndex == 2)
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: l10n.importTournamentTooltip,
              onPressed: _handleImportTournament,
            ),
          // Issue #235: el menu de usuario de la #202 pasa a ser una
          // pantalla de perfil propia; los ajustes que vivian en ese menu
          // (copia de seguridad, color de acento, tema, cerrar sesion) se
          // mueven dentro de ProfileScreen, detras de un icono de engranaje.
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: l10n.profileTooltip,
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
              label: Text(l10n.addDeckAction),
            )
          : currentIndex == 2
              ? FloatingActionButton.extended(
                  onPressed: _handleCreateTournament,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createTournamentAction),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.style), label: l10n.navDecksLabel),
          NavigationDestination(icon: const Icon(Icons.bar_chart), label: l10n.navStatsLabel),
          NavigationDestination(icon: const Icon(Icons.emoji_events), label: l10n.navTournamentsLabel),
        ],
      ),
    );
  }
}