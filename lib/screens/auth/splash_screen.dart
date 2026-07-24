import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../services/auth_service.dart';
import '../../services/quick_widget_sync_service.dart';
import '../matches/quick_register_deck_picker_screen.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );

    // Si la sesion es valida, comprueba si la app se abrio desde el widget
    // de acceso rapido (issue #10) con la app previamente cerrada -- el
    // caso de "app ya en segundo plano" se cubre aparte en main.dart via
    // HomeWidget.widgetClicked, que solo dispara mientras el engine ya esta
    // vivo. Si no hay sesion, se ignora: el usuario tiene que iniciar
    // sesion primero, y no hay mazos que elegir todavia.
    if (isLoggedIn) {
      await _openQuickRegisterIfLaunchedFromWidget();
      // Sincroniza el widget de acceso rapido con datos reales (issue #132)
      // en cada arranque con sesion iniciada. No se espera su resultado:
      // es un extra decorativo, no debe retrasar la navegacion.
      unawaited(QuickWidgetSyncService().sync());
    }
  }

  /// Ver comentario de _checkSession: navega al selector de mazo del
  /// widget de acceso rapido solo si la URI que abrio la app es la nuestra
  /// (evita interferir con cualquier otro deep link que se añada en el
  /// futuro).
  ///
  /// home_widget solo tiene implementacion nativa en Android/iOS -- en
  /// cualquier otra plataforma (Windows, web...) el canal no existe y
  /// lanzaria MissingPluginException, asi que se descarta antes de llamar.
  Future<void> _openQuickRegisterIfLaunchedFromWidget() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri?.scheme != 'decktracker' || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuickRegisterDeckPickerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}