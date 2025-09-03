// lib/pages/team_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import '../widgets/pokemon_tile.dart';
import '../widgets/team_card.dart';

class TeamPage extends StatefulWidget {
  final String? teamId; // ถ้า null = โหมดสร้างใหม่, ถ้าไม่ null = โหมดแก้ไข
  const TeamPage({super.key, this.teamId});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> with TickerProviderStateMixin {
  final c = Get.put(TeamController());
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

    // ครั้งแรก ถ้าไม่ได้เปิดมาแก้ และยังไม่มีทีมกำลังแก้ → ให้ตั้งชื่อก่อน
    if (!isEditFromRoute && c.currentEditingId.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askTeamNameFirst());
    }
  }

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    super.dispose();
  }

  // ---------- Dialog ตั้งชื่อทีม ----------
  Future<void> _askTeamNameFirst() async {
    final suggest = c.nextTeamName();
    final ctrl = TextEditingController(text: suggest);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('ตั้งชื่อทีม'),
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

  // ---------- สร้างทีมใหม่ (ล้าง selection + ตั้งชื่อใหม่) ----------
  Future<void> _newTeamFlow() async {
    c.startNewTeam();     // เคลียร์และตั้งชื่อเป็น Team N อัตโนมัติ
    await _askTeamNameFirst(); // ให้ผู้ใช้แก้ชื่อได้เลย
    Get.snackbar('New Team', 'เริ่มสร้างทีมใหม่แล้ว');
  }

  // ---------- Save / Save as New ----------
  void _saveTeam({bool asNew = false}) {
    if (c.selectedIds.isEmpty) {
      Get.snackbar('เลือกสมาชิก', 'กรุณาเลือกอย่างน้อย 1 ตัว (สูงสุด 3)');
      return;
    }

    // ถ้าต้องการ "บันทึกเป็นทีมใหม่" ให้ตัดการอ้างอิง id เดิมก่อน
    final forceNew = asNew;
    final idToSave = forceNew ? null : c.currentEditingId.value;

    final newId = c.saveCurrentTeam(id: idToSave);
    final isUpdate = !forceNew && c.currentEditingId.value != null;

    Get.snackbar('Saved', isUpdate ? 'อัปเดตทีมแล้ว ($newId)' : 'สร้างทีมใหม่แล้ว ($newId)');
  }

  // ---------- BottomSheet รายการทีม ----------
  void _openLoadTeamDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Obx(() {
        final items = c.teams;
        if (items.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(child: Text('ยังไม่มีทีมที่บันทึก')),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final t = items[i];
            return ListTile(
              title: Text(t.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สมาชิก: ${t.memberIds.join(", ")}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          c.loadTeamIntoEditor(t.id); // โหลดเข้า editor
                          Get.snackbar('Edit', 'กำลังแก้ไข "${t.name}"');
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('แก้ไขทีม'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete team'),
                              content: Text('ลบทีม "${t.name}" ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) c.deleteTeam(t.id);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('ลบทีม'),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
                c.loadTeamIntoEditor(t.id); // แตะเพื่อโหลดมาดู/แก้
              },
            );
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Obx(() => Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _teamNameCtrl..text = c.teamName.value,
                    decoration: const InputDecoration(
                      labelText: 'Team Name',
                      border: InputBorder.none,
                    ),
                    onSubmitted: c.setTeamName,
                  ),
                ),

                // ปุ่มโหลดรายการทีมทั้งหมด
                IconButton(
                  tooltip: 'Load Team',
                  onPressed: _openLoadTeamDialog,
                  icon: const Icon(Icons.folder_open),
                ),

                // ปุ่ม "บันทึกเป็นทีมใหม่"
                IconButton(
                  tooltip: 'Save as New',
                  onPressed: () => _saveTeam(asNew: true),
                  icon: const Icon(Icons.library_add),
                ),

                // ปุ่ม "บันทึก" (ทับ/สร้าง)
                IconButton(
                  tooltip: 'Save Team',
                  onPressed: _saveTeam,
                  icon: const Icon(Icons.save),
                ),

                // ปุ่ม "ทีมใหม่"
                IconButton(
                  tooltip: 'New Team',
                  onPressed: _newTeamFlow,
                  icon: const Icon(Icons.add),
                ),

                // ปุ่มรีเซ็ต selection
                IconButton(
                  tooltip: 'Reset Team',
                  onPressed: () => _confirmReset(context),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            )),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // แถบสถานะทีม + จำนวนทีมที่มี
            Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Team: ${c.selectedIds.length}/${TeamController.maxTeamSize}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: c.selectedIds.isEmpty
                              ? 0
                              : c.selectedIds.length / TeamController.maxTeamSize,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() => Chip(
                            label: Text('ทั้งหมด: ${c.teams.length} ทีม'),
                            visualDensity: VisualDensity.compact,
                          )),
                    ],
                  ),
                )),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => c.searchQuery.value = v,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search Pokémon...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            // Preview สมาชิกที่เลือก
            Obx(() {
              final team = c.allPokemon.where((p) => c.selectedIds.contains(p.id)).toList(growable: false);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: team.isEmpty ? 0 : 120,
                child: team.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (_, i) => TeamCard(p: team[i]),
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: team.length,
                      ),
              );
            }),

            // รายการโปเกมอนทั้งหมด
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = c.filteredPokemon;
                if (list.isEmpty) {
                  return const Center(child: Text('No Pokémon found.'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final selected = c.isSelected(p.id);
                    final disabled = c.teamFull && !selected;
                    return PokemonTile(
                      p: p,
                      isSelected: selected,
                      onTap: () {
                        if (disabled) {
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

  // ---------- Reset ----------
  void _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Team'),
        content: const Text('Clear all selected Pokémon?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      c.resetTeam();
      Get.snackbar('Reset', 'Team cleared');
    }
  }
}
