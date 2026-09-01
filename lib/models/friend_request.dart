import 'friend.dart';

/// Solicitud de amistad, tal y como la devuelve el backend con
/// requester/recipient ya populados (issue #92/#229).
class FriendRequestModel {
  final String id;
  final Friend requester;
  final Friend recipient;
  final String status;

  FriendRequestModel({
    required this.id,
    required this.requester,
    required this.recipient,
    required this.status,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['_id'] as String,
      requester: Friend.fromJson(json['requester'] as Map<String, dynamic>),
      recipient: Friend.fromJson(json['recipient'] as Map<String, dynamic>),
      status: json['status'] as String,
    );
  }
}
