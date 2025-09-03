import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class TeamCard extends StatelessWidget {
  final Pokemon p;
  const TeamCard({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              p.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.catching_pokemon_outlined, size: 48),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '#${p.id}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            p.name[0].toUpperCase() + p.name.substring(1),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
