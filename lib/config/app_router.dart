import 'package:go_router/go_router.dart';
import 'navigation_service.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/decks/deck_list_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/tournaments/tournaments_screen.dart';

/// Rutas con URL real por pantalla (issue #238). Alcance inicial: solo las
/// 3 pestañas principales (Mazos/Stats/Torneos), que son las que se
/// visitan con mas frecuencia y donde tiene mas sentido un enlace directo o
/// usar atras/adelante del navegador. El resto de la app sigue navegando
/// con Navigator.push imperativo sobre este mismo Navigator raiz --
/// go_router es compatible con eso: cualquier pantalla puede seguir
/// empujandose encima sin necesitar su propia ruta nombrada. Migrar el
/// resto (16 archivos con Navigator.push) queda para sub-issues futuras.
final appRouter = GoRouter(
  navigatorKey: NavigationService.navigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          LoginScreen(sessionExpired: state.uri.queryParameters['reason'] == 'expired'),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => HomeScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/decks', builder: (context, state) => const DeckListScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/stats', builder: (context, state) => const StatsScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/tournaments', builder: (context, state) => const TournamentsScreen())],
        ),
      ],
    ),
  ],
);
