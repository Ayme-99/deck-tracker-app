import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/friend.dart';
import '../../models/friend_request.dart';
import '../../services/friend_service.dart';
import '../../widgets/slow_loading_indicator.dart';

/// Gestion de amigos (issue #229): lista de amigos, solicitudes
/// entrantes/salientes, y busqueda para enviar una nueva solicitud.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final _friendService = FriendService();
  late final TabController _tabController;
  final _searchController = TextEditingController();

  List<Friend> _friends = [];
  List<FriendRequestModel> _incoming = [];
  List<FriendRequestModel> _outgoing = [];
  List<Friend> _searchResults = [];
  final Set<String> _sentTo = {};

  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _friendService.listFriends(),
        _friendService.listRequests('incoming'),
        _friendService.listRequests('outgoing'),
      ]);

      if (!mounted) return;
      setState(() {
        _friends = results[0] as List<Friend>;
        _incoming = results[1] as List<FriendRequestModel>;
        _outgoing = results[2] as List<FriendRequestModel>;
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

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _friendService.search(query.trim());
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _sendRequest(Friend user) async {
    try {
      await _friendService.sendRequest(user.username);
      if (!mounted) return;
      setState(() => _sentTo.add(user.id));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _acceptRequest(FriendRequestModel request) async {
    try {
      await _friendService.acceptRequest(request.id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _rejectRequest(FriendRequestModel request) async {
    try {
      await _friendService.rejectRequest(request.id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _confirmRemoveFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar amistad'),
        content: Text('¿Seguro que quieres eliminar a "${friend.username}" de tus amigos?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _friendService.removeFriend(friend.id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return const Center(
        child: Text('Todavía no tienes amigos añadidos', style: TextStyle(color: AppColors.muted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(friend.username),
              trailing: IconButton(
                icon: Icon(Icons.person_remove_outlined, color: Theme.of(context).colorScheme.error),
                tooltip: 'Eliminar amistad',
                onPressed: () => _confirmRemoveFriend(friend),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_incoming.isEmpty && _outgoing.isEmpty) {
      return const Center(
        child: Text('No hay solicitudes pendientes', style: TextStyle(color: AppColors.muted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        children: [
          if (_incoming.isNotEmpty) ...[
            const Text('Entrantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM)),
            const SizedBox(height: AppSizes.spacingS),
            ..._incoming.map((request) => Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(request.requester.username),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: AppColors.success),
                          tooltip: 'Aceptar',
                          onPressed: () => _acceptRequest(request),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                          tooltip: 'Rechazar',
                          onPressed: () => _rejectRequest(request),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: AppSizes.spacingM),
          ],
          if (_outgoing.isNotEmpty) ...[
            const Text('Salientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppSizes.textM)),
            const SizedBox(height: AppSizes.spacingS),
            ..._outgoing.map((request) => Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(request.recipient.username),
                    trailing: const Text('Pendiente', style: TextStyle(color: AppColors.muted)),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por username',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(AppSizes.spacingS),
                      child: SizedBox(
                        height: AppSizes.spinnerSmall,
                        width: AppSizes.spinnerSmall,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: _handleSearch,
          ),
          const SizedBox(height: AppSizes.spacingM),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.trim().isEmpty
                          ? 'Busca a alguien por su nombre de usuario'
                          : 'Sin resultados',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final alreadySent = _sentTo.contains(user.id) ||
                          _outgoing.any((r) => r.recipient.id == user.id) ||
                          _friends.any((f) => f.id == user.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(user.username),
                          trailing: alreadySent
                              ? const Text('Enviada', style: TextStyle(color: AppColors.muted))
                              : TextButton(
                                  onPressed: () => _sendRequest(user),
                                  child: const Text('Añadir'),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amigos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Amigos'),
            Tab(text: 'Solicitudes'),
            Tab(text: 'Buscar'),
          ],
        ),
      ),
      body: _isLoading
          ? const SlowLoadingIndicator()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacingL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage', textAlign: TextAlign.center),
                        const SizedBox(height: AppSizes.spacingM),
                        FilledButton(onPressed: _loadData, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFriendsTab(),
                    _buildRequestsTab(),
                    _buildSearchTab(),
                  ],
                ),
    );
  }
}
