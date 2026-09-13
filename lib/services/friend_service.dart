import '../models/friend.dart';
import '../models/friend_request.dart';
import 'api_service.dart';

/// Cliente del backend de amistad (issue #92): busqueda de usuarios,
/// solicitudes, lista de amigos, y bloqueo de usuarios (issue #281).
class FriendService {
  final _api = ApiService();

  Future<List<Friend>> search(String query) async {
    final response = await _api.get('/friends/search?q=${Uri.encodeQueryComponent(query)}');
    return (response as List).map((u) => Friend.fromJson(u as Map<String, dynamic>)).toList();
  }

  Future<void> sendRequest(String username) async {
    await _api.post('/friends/requests', {'username': username});
  }

  Future<List<FriendRequestModel>> listRequests(String type) async {
    final response = await _api.get('/friends/requests?type=$type');
    return (response as List).map((r) => FriendRequestModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> acceptRequest(String id) async {
    await _api.post('/friends/requests/$id/accept', {});
  }

  Future<void> rejectRequest(String id) async {
    await _api.post('/friends/requests/$id/reject', {});
  }

  Future<List<Friend>> listFriends() async {
    final response = await _api.get('/friends');
    return (response as List).map((u) => Friend.fromJson(u as Map<String, dynamic>)).toList();
  }

  Future<void> removeFriend(String friendId) async {
    await _api.delete('/friends/$friendId');
  }

  // Issue #281: bloquear impide nuevas solicitudes en cualquier direccion.
  // Si el usuario ya era amigo, el server convierte esa relacion aceptada
  // directamente en bloqueada -- no hace falta llamar antes a removeFriend.
  Future<void> blockUser(String userId) async {
    await _api.post('/friends/$userId/block', {});
  }

  Future<void> unblockUser(String userId) async {
    await _api.delete('/friends/$userId/block');
  }

  Future<List<Friend>> listBlocked() async {
    final response = await _api.get('/friends/blocked');
    return (response as List).map((u) => Friend.fromJson(u as Map<String, dynamic>)).toList();
  }
}