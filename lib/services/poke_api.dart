import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokeApi {
  static Future<List<Pokemon>> fetchPokemon({int limit = 151}) async {
    final res = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=$limit'),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load Pokémon list (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List).cast<Map<String, dynamic>>();

    final list = <Pokemon>[];
    for (var i = 0; i < results.length; i++) {
      final url = results[i]['url'] as String;
      final name = results[i]['name'] as String;
      // url ลงท้าย .../pokemon/{id}/ → ดึง id จากพาร์ทสุดท้ายที่เป็นตัวเลข
      final parts = url.split('/').where((s) => s.isNotEmpty).toList();
      final id = int.tryParse(parts.last) ?? (i + 1);
      list.add(Pokemon(id: id, name: name));
    }
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }
}
