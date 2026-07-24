import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/matches/quick_register_deck_picker_screen.dart';
import 'config/navigation_service.dart';
import 'services/theme_preference_service.dart';
import 'package:deck_tracker_app/styles/theme.dart';

Future<void> main() async {
  // Necesario para poder leer flutter_secure_storage antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // Carga la preferencia de tema guardada (issue #129) antes de arrancar,
  // para no mostrar un flash del tema por defecto (sistema).
  await ThemePreferenceService.load();
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
        return MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          title: 'Deck Tracker',
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}