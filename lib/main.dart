import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const DeckTrackerApp());
}

class DeckTrackerApp extends StatelessWidget {
  const DeckTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deck Tracker',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}