import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonTile extends StatefulWidget {
  final Pokemon p;
  final bool isSelected;
  final VoidCallback onTap;

  const PokemonTile({
    super.key,
    required this.p,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<PokemonTile> createState() => _PokemonTileState();
}

class _PokemonTileState extends State<PokemonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant PokemonTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // pulse เล็กน้อยเมื่อสถานะเปลี่ยน
    if (oldWidget.isSelected != widget.isSelected) {
      _controller.forward(from: 0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return ScaleTransition(
      scale: _scale,
      child: ListTile(
        onTap: widget.onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade100,
          child: ClipOval(
            child: Image.network(
              p.imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.catching_pokemon_outlined),
            ),
          ),
        ),
        title: Text(
          '#${p.id}  ${p.name[0].toUpperCase()}${p.name.substring(1)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: widget.isSelected ? Colors.red : null,
          ),
        ),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: widget.isSelected
              ? const Icon(Icons.check_circle, key: ValueKey('on'))
              : const Icon(Icons.circle_outlined, key: ValueKey('off')),
        ),
      ),
    );
  }
}
