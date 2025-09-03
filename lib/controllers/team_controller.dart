// lib/controllers/team_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/pokemon.dart';
import '../models/team.dart';
import '../services/poke_api.dart';

class TeamController extends GetxController {
  // ====== กติกาเลือกสมาชิก ======
  static const int maxTeamSize = 3;

  // ====== Keys สำหรับ persist ======
  // state ของหน้าจอแก้ไขทีม (Editor)
  static const _boxKeyTeamName = 'team_name';
  static const _boxKeyTeamList = 'team_list';
  static const _boxKeySelectedIds = 'selected_ids';
  // รายชื่อทีมทั้งหมด (หลายทีม)
  static const _boxKeyTeams = 'teams_v1';

  final box = GetStorage();

  // ====== UI/Editor state ======
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final allPokemon = <Pokemon>[].obs;
  final selectedIds = <int>{}.obs;
  final teamName = 'My Dream Team'.obs;

  // ====== หลายทีม (จัดเก็บครบทุกทีม) ======
  final teams = <TeamModel>[].obs;
  final currentEditingId = RxnString(); // id ทีมที่กำลังแก้ (ถ้ามี)

  // ---------- Derived ----------
  List<Pokemon> get filteredPokemon {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return allPokemon;
    return allPokemon.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  bool get teamFull => selectedIds.length >= maxTeamSize;
  bool isSelected(int id) => selectedIds.contains(id);

  // ---------- สร้างชื่อทีมถัดไปอัตโนมัติ ----------
  /// สร้างชื่อทีมถัดไปอัตโนมัติ: Team 1, Team 2, ...
  String nextTeamName() {
    int maxNum = 0;
    for (final t in teams) {
      final m = RegExp(r'^Team\s+(\d+)$', caseSensitive: false)
          .firstMatch(t.name.trim());
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > maxNum) maxNum = n;
      }
    }
    return 'Team ${maxNum + 1}';
  }

  // ---------- เริ่มสร้างทีมใหม่ด้วยชื่ออัตโนมัติ ----------
  void startNewTeam() {
    selectedIds.clear();
    teamName.value = nextTeamName();
    currentEditingId.value = null;
    _persistEditor();
  }

  // ---------- Fetch Pokédex ----------
  Future<void> fetchPokemon({int limit = 151}) async {
    isLoading.value = true;
    try {
      final list = await PokeApi.fetchPokemon(limit: limit);
      if (list.length < 20) {
        throw Exception('Pokémon list must be at least 20.');
      }
      allPokemon.assignAll(list);
      _restoreEditorFromStorage();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch Pokémon: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------- เลือก/ยกเลิก ----------
  void toggleSelect(Pokemon p) {
    if (selectedIds.contains(p.id)) {
      selectedIds.remove(p.id);
    } else {
      if (teamFull) {
        Get.snackbar('Team full', 'เลือกได้สูงสุด $maxTeamSize ตัว');
        return;
      }
      selectedIds.add(p.id);
    }
    _persistEditor();
  }

  // ---------- ชื่อทีม ----------
  void setTeamName(String name) {
    final v = name.trim().isEmpty ? nextTeamName() : name.trim();
    teamName.value = v;
    _persistEditor();
  }

  // ---------- Reset editor ----------
  void resetTeam() {
    selectedIds.clear();
    teamName.value = nextTeamName(); // ใช้ชื่ออัตโนมัติแทนคงที่
    currentEditingId.value = null;
    _persistEditor();
  }

  // ---------- Persist/Restore (เฉพาะ editor) ----------
  void _persistEditor() {
    box.write(_boxKeyTeamName, teamName.value);
    box.write(_boxKeySelectedIds, selectedIds.toList());
    final team = allPokemon.where((p) => selectedIds.contains(p.id)).toList();
    box.write(_boxKeyTeamList, team.map((e) => e.toJson()).toList());
  }

  void _restoreEditorFromStorage() {
    final name = box.read<String>(_boxKeyTeamName);
    if (name != null && name.isNotEmpty) {
      teamName.value = name;
    } else {
      // ถ้าไม่เคยมีชื่อในแคช ให้ตั้งเป็นชื่ออัตโนมัติทันที
      teamName.value = nextTeamName();
    }

    final ids = (box.read<List>(_boxKeySelectedIds) ?? []).cast<int>();
    selectedIds
      ..clear()
      ..addAll(ids.take(maxTeamSize));

    // (optional) เติมลิสต์เริ่มต้นจาก cache ถ้ายังไม่มี
    final cachedTeamRaw = (box.read<List>(_boxKeyTeamList) ?? []);
    final cachedTeam = cachedTeamRaw
        .cast<Map>()
        .map((e) => Pokemon.fromJson(e.cast<String, dynamic>()))
        .toList();
    if (allPokemon.isEmpty && cachedTeam.isNotEmpty) {
      allPokemon.assignAll(cachedTeam);
    }

    _loadTeams(); // โหลดรายการทีมทั้งหมดด้วย
  }

  // ====== จัดการ "หลายทีม" (CRUD + Persist) ======
  void _loadTeams() {
    final raw = (box.read<List>(_boxKeyTeams) ?? []);
    final list = raw
        .cast<Map>()
        .map((e) => TeamModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    teams.assignAll(list);
  }

  void _saveTeams() {
    box.write(_boxKeyTeams, teams.map((e) => e.toJson()).toList());
  }

  TeamModel? getTeamById(String id) =>
      teams.firstWhereOrNull((t) => t.id == id);

  /// ✅ บันทึกทีม:
  /// - ถ้ามี [id] *หรือ* currentEditingId → อัปเดตทีมเดิม
  /// - ถ้าไม่มี → สร้างทีมใหม่ (ถ้าไม่ตั้งชื่อ จะตั้งเป็น Team N อัตโนมัติ)
  String saveCurrentTeam({String? id}) {
    final effectiveId = id ?? currentEditingId.value;
    final ids = selectedIds.toList().take(maxTeamSize).toList();

    // ถ้าไม่ได้ตั้งชื่อ หรือเป็นชื่อดีฟอลต์เดิม ให้ใช้ Team N
    final rawName = teamName.value.trim();
    final name = (rawName.isEmpty || rawName == 'My Dream Team')
        ? nextTeamName()
        : rawName;

    if (effectiveId == null) {
      // --- create ---
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      teams.add(TeamModel(id: newId, name: name, memberIds: ids));
      _saveTeams();
      currentEditingId.value = newId;
      // อัปเดตชื่อใน editor ด้วย (กันเคสผู้ใช้ยังเห็นชื่อเดิม)
      teamName.value = name;
      _persistEditor();
      return newId;
    } else {
      // --- update (บันทึกทับทีมเดิม) ---
      final idx = teams.indexWhere((t) => t.id == effectiveId);
      if (idx >= 0) {
        teams[idx].name = name;
        teams[idx].memberIds = ids;
        teams.refresh();
      } else {
        // กรณี id ไม่พบ (เช่น storage เพิ่งถูกลบ) → สร้างใหม่ด้วย id เดิม
        teams.add(TeamModel(id: effectiveId, name: name, memberIds: ids));
      }
      _saveTeams();
      currentEditingId.value = effectiveId;
      teamName.value = name;
      _persistEditor();
      return effectiveId;
    }
  }

  /// ✅ โหลดทีมเดิมเข้ามาแก้ใน editor และจำ id ไว้ (ใช้กับปุ่ม "แก้ไขทีม")
  void loadTeamIntoEditor(String id) {
    final t = getTeamById(id);
    if (t == null) return;
    teamName.value = t.name;
    selectedIds
      ..clear()
      ..addAll(t.memberIds.take(maxTeamSize));
    currentEditingId.value = id;
    _persistEditor();
  }

  void deleteTeam(String id) {
    teams.removeWhere((t) => t.id == id);
    _saveTeams();
    // ถ้าลบทีกำลังแก้ ให้รีเซ็ต editor ด้วย
    if (currentEditingId.value == id) {
      resetTeam();
    }
  }
}
