import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'config/navigation_service.dart';

void main() {
  runApp(const DeckTrackerApp());
}

class DeckTrackerApp extends StatelessWidget {
  const DeckTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'Deck Tracker',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // sigue el ajuste del movil automaticamente
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}