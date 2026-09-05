import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:home_widget/home_widget.dart';
import 'screens/matches/quick_register_deck_picker_screen.dart';
import 'config/app_router.dart';
import 'config/navigation_service.dart';
import 'l10n/app_localizations.dart';
import 'services/accent_color_service.dart';
import 'services/theme_preference_service.dart';
import 'package:deck_tracker_app/styles/theme.dart';

Future<void> main() async {
  // Necesario para poder leer flutter_secure_storage antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // Issue #294: quita el "#" de las URLs en web (deck-tracker-web.onrender.com/decks
  // en vez de /#/decks). Sin efecto en plataformas no-web. Requiere que el
  // hosting redirija cualquier subruta a index.html (ver web/_redirects),
  // o recargar la pagina en una subruta directa daria 404.
  usePathUrlStrategy();
  // Carga la preferencia de tema y de color de acento guardadas (issues
  // #129 y #168) antes de arrancar, para no mostrar un flash de los
  // valores por defecto si el usuario ya habia elegido otros.
  await ThemePreferenceService.load();
  await AccentColorService.load();
  runApp(const DeckTrackerApp());
}

class DeckTrackerApp extends StatefulWidget {
  const DeckTrackerApp({super.key});

  @override
  State<DeckTrackerApp> createState() => _DeckTrackerAppState();
}

class _DeckTrackerAppState extends State<DeckTrackerApp> {
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();

    // Widget de acceso rapido (issue #10): caso "app ya en segundo plano".
    // El caso "app cerrada del todo" se cubre en splash_screen.dart via
    // HomeWidget.initiallyLaunchedFromHomeWidget(), que solo devuelve algo
    // en un arranque en frio -- este stream es el complementario, dispara
    // mientras el motor de Flutter ya esta corriendo.
    //
    // home_widget solo tiene implementacion nativa en Android/iOS -- en
    // cualquier otra plataforma (Windows, web...) el canal no existe y
    // suscribirse lanzaria MissingPluginException.
    if (!kIsWeb && Platform.isAndroid) {
      _widgetClickSubscription = HomeWidget.widgetClicked.listen((uri) {
        if (uri?.scheme != 'decktracker') return;
        NavigationService.navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const QuickRegisterDeckPickerScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemePreferenceService.themeMode,
      builder: (context, mode, _) {
        // Anidado con el de accentKey (issue #168): un cambio de color de
        // acento tambien tiene que reconstruir el MaterialApp, porque
        // buildAppTheme lee AppColors.primary (ya actualizado por
        // AccentColorService antes de notificar) en el momento de construir.
        return ValueListenableBuilder<String>(
          valueListenable: AccentColorService.accentKey,
          builder: (context, accentKey, _) {
            return MaterialApp.router(
              routerConfig: appRouter,
              title: 'Deck Tracker',
              theme: buildAppTheme(Brightness.light),
              darkTheme: buildAppTheme(Brightness.dark),
              themeMode: mode,
              debugShowCheckedModeBanner: false,
              // Issue #261: textos centralizados en lib/l10n/app_es.arb.
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        );
      },
    );
  }
}