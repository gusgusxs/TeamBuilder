// lib/pages/team_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import '../widgets/pokemon_tile.dart';
import '../widgets/team_card.dart';

class TeamPage extends StatefulWidget {
  final String? teamId;
  const TeamPage({super.key, this.teamId});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final c = Get.find<TeamController>();
  late final TextEditingController _teamNameCtrl;
  bool get isEditFromRoute => widget.teamId != null;

  @override
  void initState() {
    super.initState();
    _teamNameCtrl = TextEditingController();
    c.fetchPokemon(limit: 151);

    if (isEditFromRoute) {
      c.loadTeamIntoEditor(widget.teamId!);
    }

    ever<String>(c.teamName, (name) {
      _teamNameCtrl
        ..text = name
        ..selection = TextSelection.fromPosition(TextPosition(offset: name.length));
    });

    if (!isEditFromRoute && c.currentEditingId.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askTeamNameFirst());
    }
  }

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _askTeamNameFirst() async {
    final suggest = c.nextTeamName();
    final ctrl = TextEditingController(text: suggest);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('ตั้งชื่อทีมก่อนเริ่ม'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            hintText: 'เช่น Team 1',
          ),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ตกลง')),
        ],
      ),
    );
    if (ok == true) {
      final name = ctrl.text.trim().isEmpty ? suggest : ctrl.text.trim();
      c.setTeamName(name);
    }
  }

  void _saveTeam({bool asNew = false}) {
    if (c.selectedIds.isEmpty) {
      Get.snackbar('เลือกสมาชิก', 'กรุณาเลือกอย่างน้อย 1 ตัว (สูงสุด 3)');
      return;
    }
    final id = c.saveCurrentTeam(id: asNew ? null : c.currentEditingId.value);
    final updated = !asNew && c.currentEditingId.value != null;
    Get.snackbar('Saved', updated ? 'อัปเดตทีมแล้ว ($id)' : 'สร้างทีมใหม่แล้ว ($id)');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Obx(() => TextField(
              controller: _teamNameCtrl..text = c.teamName.value,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: InputBorder.none,
              ),
              onSubmitted: c.setTeamName,
            )),
        actions: [
          IconButton(
            tooltip: 'Save Team',
            onPressed: _saveTeam,
            icon: const Icon(Icons.save),
          ),
          IconButton(
            tooltip: 'Save as New',
            onPressed: () => _saveTeam(asNew: true),
            icon: const Icon(Icons.library_add),
          ),
          IconButton(
            tooltip: 'Reset Team',
            onPressed: () => c.resetTeam(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Obx(() => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Text('Team: ${c.selectedIds.length}/${TeamController.maxTeamSize}'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: c.selectedIds.isEmpty
                              ? 0
                              : c.selectedIds.length / TeamController.maxTeamSize,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (c.teamFull)
                        const Chip(label: Text('FULL'), visualDensity: VisualDensity.compact),
                    ],
                  ),
                )),
            // Search
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                onChanged: (v) => c.searchQuery.value = v,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search Pokémon...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // Selected preview
            Obx(() {
              final team = c.allPokemon.where((p) => c.selectedIds.contains(p.id)).toList();
              if (team.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: team.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => TeamCard(p: team[i]),
                ),
              );
            }),
            // Pokémon list
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
                final list = c.filteredPokemon;
                if (list.isEmpty) return const Center(child: Text('No Pokémon found.'));
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final selected = c.isSelected(p.id);

                    return PokemonTile(
                      p: p,
                      isSelected: selected,
                      onTap: () {
                        // ✅ เช็คสถานะ "สด" ตอนแตะทุกครั้ง ไม่ใช้ตัวแปรค้าง
                        final selectedNow = c.isSelected(p.id);
                        final teamFullNow = c.teamFull;
                        if (!selectedNow && teamFullNow) {
                          Get.snackbar('Team full', 'เลือกได้สูงสุด ${TeamController.maxTeamSize} ตัว');
                          return;
                        }
                        c.toggleSelect(p);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
