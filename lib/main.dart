import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';
import 'config/navigation_service.dart';
import 'package:deck_tracker_app/styles/theme.dart';

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
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}