class Pokemon {
  final int id;
  final String name;

  Pokemon({required this.id, required this.name});

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Pokemon.fromJson(Map<String, dynamic> j) =>
      Pokemon(id: j['id'] as int, name: j['name'] as String);
}
