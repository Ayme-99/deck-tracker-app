class OpponentArchetype {
  final String? id;
  final String name;
  final String? sprite1;
  final String? sprite2;

  OpponentArchetype({
    this.id,
    required this.name,
    this.sprite1,
    this.sprite2,
  });

  factory OpponentArchetype.fromJson(Map<String, dynamic> json) {
    return OpponentArchetype(
      id: json['_id'],
      name: json['name'],
      sprite1: json['sprite1'],
      sprite2: json['sprite2'],
    );
  }
}