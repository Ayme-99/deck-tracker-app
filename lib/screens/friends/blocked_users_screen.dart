import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/friend.dart';
import '../../services/friend_service.dart';
import '../../widgets/slow_loading_indicator.dart';
import '../../l10n/app_localizations.dart';

/// Lista de usuarios bloqueados (issue #281), accesible desde FriendsScreen.
/// Unica pantalla desde la que se puede desbloquear -- bloquear se hace
/// desde la lista de amigos o desde busqueda de usuarios.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _friendService = FriendService();
  List<Friend> _blocked = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final blocked = await _friendService.listBlocked();
      if (!mounted) return;
      setState(() {
        _blocked = blocked;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _unblock(Friend user) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _friendService.unblockUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userUnblockedSnackbar(user.username))),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.unblockUserError(e.toString().replaceFirst('Exception: ', '')))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsersScreenTitle)),
      body: _isLoading
          ? const SlowLoadingIndicator()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.genericErrorLabel(_errorMessage!), textAlign: TextAlign.center),
                        const SizedBox(height: AppSizes.spacingM),
                        FilledButton(onPressed: _loadData, child: Text(l10n.retryAction)),
                      ],
                    ),
                  ),
                )
              : _blocked.isEmpty
                  ? Center(child: Text(l10n.noBlockedUsersYet, style: const TextStyle(color: AppColors.muted)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.spacingM),
                        itemCount: _blocked.length,
                        itemBuilder: (context, index) {
                          final user = _blocked[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(user.username),
                              trailing: TextButton(
                                onPressed: () => _unblock(user),
                                child: Text(l10n.unblockUserAction),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}