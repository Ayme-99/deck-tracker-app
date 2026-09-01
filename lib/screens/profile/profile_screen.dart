import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/accent_color_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_preference_service.dart';
import '../backup/backup_screen.dart';
import '../friends/friends_screen.dart';
import '../../widgets/slow_loading_indicator.dart';

/// Pantalla de perfil de usuario (issue #235): primer paso hacia una futura
/// pantalla de perfil completa (gestion de amigos, stats de cuenta...),
/// evolucion del menu de usuario montado en la #202. Los ajustes que antes
/// vivian en ese menu (copia de seguridad, color de acento, tema, cerrar
/// sesion) se mueven aqui, detras de un icono de engranaje -- en el mismo
/// sitio de la AppBar donde antes vivia el icono de usuario en home_screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  String? _username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final me = await _authService.getMe();
      if (!mounted) return;
      setState(() {
        _username = me['username'] as String?;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  /// Selector de color de acento (issue #168): dialogo con un circulo por
  /// cada color de la paleta fija, marcando el actualmente elegido.
  Future<void> _showAccentPicker() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color de acento'),
        content: Wrap(
          spacing: AppSizes.spacingM,
          runSpacing: AppSizes.spacingM,
          children: AccentColorService.palette.entries.map((entry) {
            final isSelected = entry.key == AccentColorService.accentKey.value;
            return InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => Navigator.of(context).pop(entry.key),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingXS),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: AppColors.textPrimary, width: 3) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(AccentColorService.labels[entry.key]!, style: const TextStyle(fontSize: AppSizes.textXS)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) AccentColorService.setAccent(selected);
  }

  /// Selector de tema (issue #202): mismo patron de dialogo que el color de
  /// acento.
  Future<void> _showThemePicker() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Tema'),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(mode),
              child: Row(
                children: [
                  Icon(switch (mode) {
                    ThemeMode.system => Icons.brightness_auto_outlined,
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                  }),
                  const SizedBox(width: AppSizes.spacingM),
                  Text(switch (mode) {
                    ThemeMode.system => 'Automático (sistema)',
                    ThemeMode.light => 'Claro',
                    ThemeMode.dark => 'Oscuro',
                  }),
                ],
              ),
            ),
        ],
      ),
    );

    if (selected != null) ThemePreferenceService.setThemeMode(selected);
  }

  Future<void> _showSettingsMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_backup_restore_outlined),
              title: const Text('Copia de seguridad'),
              onTap: () => Navigator.of(context).pop('backup'),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Color de acento'),
              onTap: () => Navigator.of(context).pop('accent'),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Tema'),
              onTap: () => Navigator.of(context).pop('theme'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () => Navigator.of(context).pop('logout'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    switch (action) {
      case 'backup':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BackupScreen()),
        );
      case 'accent':
        _showAccentPicker();
      case 'theme':
        _showThemePicker();
      case 'logout':
        _handleLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const SlowLoadingIndicator()
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: AppSizes.iconHuge / 2,
                      child: Icon(Icons.person, size: AppSizes.iconLarge),
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    Text(
                      _username ?? 'Usuario',
                      style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.spacingL),
                    // Issue #229: gestion de amigos, colgando de la pantalla
                    // de perfil (candidato ya previsto en la #235). Ancho
                    // fijo: dentro del Column(mainAxisSize.min) del Center,
                    // un ListTile sin restriccion de ancho intentaria
                    // expandirse de forma infinita.
                    SizedBox(
                      width: 280,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: const Text('Amigos'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FriendsScreen()),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
