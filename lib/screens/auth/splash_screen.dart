import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../services/auth_service.dart';
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
    if (isLoggedIn) await _openQuickRegisterIfLaunchedFromWidget();
  }

  /// Ver comentario de _checkSession: navega al selector de mazo del
  /// widget de acceso rapido solo si la URI que abrio la app es la nuestra
  /// (evita interferir con cualquier otro deep link que se añada en el
  /// futuro).
  Future<void> _openQuickRegisterIfLaunchedFromWidget() async {
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