import 'package:flutter/material.dart';
import 'package:deck_tracker_app/styles.dart';
import '../../models/deck.dart';
import '../../models/tournament_invite.dart';
import '../../services/deck_service.dart';
import '../../services/tournament_invite_service.dart';
import '../../widgets/slow_loading_indicator.dart';

/// Invitaciones a torneos hosted recibidas de amigos (issue #242): aceptar
/// (eligiendo con que mazo propio unirse) o rechazar.
class TournamentInvitesScreen extends StatefulWidget {
  const TournamentInvitesScreen({super.key});

  @override
  State<TournamentInvitesScreen> createState() => _TournamentInvitesScreenState();
}

class _TournamentInvitesScreenState extends State<TournamentInvitesScreen> {
  final _inviteService = TournamentInviteService();
  final _deckService = DeckService();

  List<TournamentInvite> _invites = [];
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
      final invites = await _inviteService.listMyInvites();
      if (!mounted) return;
      setState(() {
        _invites = invites;
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

  Future<void> _accept(TournamentInvite invite) async {
    List<Deck> decks;
    try {
      decks = await _deckService.getDecks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tus mazos: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
      return;
    }

    if (!mounted) return;
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas al menos un mazo propio para unirte a un torneo')),
      );
      return;
    }

    final selectedDeck = await showDialog<Deck>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('¿Con qué mazo te unes?'),
        children: decks
            .map((d) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(d),
                  child: Text(d.name),
                ))
            .toList(),
      ),
    );

    if (selectedDeck == null || !mounted) return;

    try {
      await _inviteService.acceptInvite(invite.id, deckId: selectedDeck.id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  Future<void> _reject(TournamentInvite invite) async {
    try {
      await _inviteService.rejectInvite(invite.id);
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitaciones a torneos')),
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
              : _invites.isEmpty
                  ? const Center(
                      child: Text('No tienes invitaciones pendientes', style: TextStyle(color: AppColors.muted)),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.spacingM),
                        itemCount: _invites.length,
                        itemBuilder: (context, index) {
                          final invite = _invites[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
                            child: ListTile(
                              title: Text(invite.tournamentName ?? 'Torneo'),
                              subtitle: Text('Rol: ${invite.role == 'admin' ? 'Admin' : 'Invitado'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: AppColors.success),
                                    tooltip: 'Aceptar',
                                    onPressed: () => _accept(invite),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                                    tooltip: 'Rechazar',
                                    onPressed: () => _reject(invite),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
