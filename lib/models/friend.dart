/// Un usuario (amigo, o resultado de busqueda) tal y como lo expone el
/// backend de amistad (issue #92/#229): solo id y username, nunca mas datos
/// de la cuenta.
class Friend {
  final String id;
  final String username;

  Friend({required this.id, required this.username});

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['_id'] as String,
      username: json['username'] as String,
    );
  }
}
