import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../services/accent_color_service.dart';
import '../../services/auth_service.dart';
import '../../services/deck_service.dart';
import '../../services/friend_service.dart';
import '../../services/stats_service.dart';
import '../../services/theme_preference_service.dart';
import '../backup/backup_screen.dart';
import 'change_password_dialog.dart';
import '../friends/friends_screen.dart';
import '../tournaments/tournament_invites_screen.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../../l10n/app_localizations.dart';

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

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final _authService = AuthService();
  final _deckService = DeckService();
  final _friendService = FriendService();
  final _statsService = StatsService();

  String? _username;
  bool _emailVerified = true; // hasta que se sepa lo contrario no se muestra el aviso
  bool _isLoading = true;
  bool _isResendingVerification = false;

  // Issue #276/#279/#280/#284: resumen rapido + contadores sociales +
  // version de la app, todo cargado de golpe al entrar al perfil.
  int _deckCount = 0;
  int _totalMatches = 0;
  num _winRate = 0;
  int _friendCount = 0;
  int _pendingRequestCount = 0;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Issue #268: la verificacion del email pasa por el navegador (el enlace
  // del correo), fuera de la app -- sin esto, al volver el perfil se queda
  // con el estado "no verificado" que tenia al entrar, aunque ya se haya
  // confirmado desde fuera.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // Cada dato viene de un servicio distinto -- si uno falla (ej. sin
      // conexion puntual), no debe tirar abajo los demas, asi que cada
      // future tiene su propio fallback en vez de un solo try/catch total.
      final results = await Future.wait([
        _authService.getMe(),
        _deckService.getDecks().then((d) => d.length).catchError((_) => 0),
        _statsService.getGlobalOverview().catchError((_) => <String, dynamic>{}),
        _friendService.listFriends().then((f) => f.length).catchError((_) => 0),
        _friendService.listRequests('incoming').then((r) => r.length).catchError((_) => 0),
        PackageInfo.fromPlatform().then((p) => '${p.version}+${p.buildNumber}').catchError((_) => ''),
      ]);

      if (!mounted) return;

      final me = results[0] as Map<String, dynamic>;
      final overview = results[2] as Map<String, dynamic>;

      setState(() {
        _username = me['username'] as String?;
        // Cuentas creadas antes de la #268 no tienen email todavia -- no
        // tiene sentido pedirles que "verifiquen" algo que no existe.
        _emailVerified = me['email'] == null || me['emailVerified'] == true;
        _deckCount = results[1] as int;
        _totalMatches = overview['totalMatches'] as int? ?? 0;
        _winRate = overview['winRate'] as num? ?? 0;
        _friendCount = results[3] as int;
        _pendingRequestCount = results[4] as int;
        _appVersion = results[5] as String;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResendingVerification = true);
    final l10n = AppLocalizations.of(context);
    try {
      await _authService.resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationEmailSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resendVerificationError(e.toString().replaceFirst('Exception: ', '')))),
      );
    } finally {
      if (mounted) setState(() => _isResendingVerification = false);
    }
  }

  Widget _profileStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: AppSizes.textXS)),
      ],
    );
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  /// Selector de color de acento (issue #168): dialogo con un circulo por
  /// cada color de la paleta fija, marcando el actualmente elegido.
  Future<void> _showAccentPicker() async {
    final l10n = AppLocalizations.of(context);
    final labels = AccentColorService.labelsFor(l10n);
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accentColorPickerTitle),
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
                    Text(labels[entry.key]!, style: const TextStyle(fontSize: AppSizes.textXS)),
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
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.themePickerTitle),
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
                    ThemeMode.system => l10n.themeModeSystem,
                    ThemeMode.light => l10n.themeModeLight,
                    ThemeMode.dark => l10n.themeModeDark,
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
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_backup_restore_outlined),
              title: Text(l10n.backupSettingsAction),
              onTap: () => Navigator.of(context).pop('backup'),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.accentColorSettingsAction),
              onTap: () => Navigator.of(context).pop('accent'),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: Text(l10n.themeSettingsAction),
              onTap: () => Navigator.of(context).pop('theme'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.changePasswordSettingsAction),
              onTap: () => Navigator.of(context).pop('change_password'),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.reportBugAction),
              onTap: () => Navigator.of(context).pop('report_bug'),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.logoutAction),
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
      case 'change_password':
        showChangePasswordDialog(context);
      case 'report_bug':
        launchUrl(
          Uri.parse('https://github.com/Ayme-99/deck-tracker-app/issues/new?template=user_bug_report.md'),
          mode: LaunchMode.externalApplication,
        );
      case 'logout':
        _handleLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTooltip,
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const SlowLoadingIndicator()
          : SingleChildScrollView(
              child: Center(
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
                      _username ?? l10n.defaultUsername,
                      style: const TextStyle(fontSize: AppSizes.textL, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.spacingL),
                    if (!_emailVerified) ...[
                      SizedBox(
                        width: 280,
                        child: Card(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.spacingM),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.mark_email_unread_outlined, color: AppColors.warning, size: AppSizes.iconSmall),
                                    const SizedBox(width: AppSizes.spacingS),
                                    Expanded(child: Text(l10n.emailVerificationBannerText)),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.spacingS),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isResendingVerification ? null : _resendVerificationEmail,
                                    child: _isResendingVerification
                                        ? const SizedBox(
                                            height: AppSizes.spinnerSmall,
                                            width: AppSizes.spinnerSmall,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(l10n.resendVerificationAction),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                    ],
                    // Issue #276: resumen rapido de actividad -- solo tiene
                    // sentido para el dueno del perfil (no hay perfil
                    // "de otro usuario" todavia, asi que siempre se muestra).
                    SizedBox(
                      width: 280,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.spacingM),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _profileStat('$_deckCount', l10n.navDecksLabel),
                              _profileStat('$_totalMatches', l10n.matchesSectionTitle),
                              _profileStat('$_winRate%', l10n.winRateLabel),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    // Issue #229/#279/#280: gestion de amigos, colgando de la
                    // pantalla de perfil (candidato ya previsto en la #235).
                    // Ancho fijo: dentro del Column(mainAxisSize.min) del
                    // Center, un ListTile sin restriccion de ancho intentaria
                    // expandirse de forma infinita.
                    SizedBox(
                      width: 280,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: Text(l10n.friendsMenuAction),
                          subtitle: Text(l10n.friendsCountLabel(_friendCount)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_pendingRequestCount > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingS, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                                  ),
                                  child: Text(
                                    '$_pendingRequestCount',
                                    style: const TextStyle(color: Colors.white, fontSize: AppSizes.textXS, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.spacingXS),
                              ],
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FriendsScreen()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    // Issue #242: invitaciones a torneos hosted recibidas.
                    SizedBox(
                      width: 280,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: Text(l10n.tournamentInvitesMenuAction),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TournamentInvitesScreen()),
                          ),
                        ),
                      ),
                    ),
                    if (_appVersion != null && _appVersion!.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spacingL),
                      Text(
                        l10n.appVersionLabel(_appVersion!),
                        style: const TextStyle(color: AppColors.muted, fontSize: AppSizes.textXS),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
    );
  }
}