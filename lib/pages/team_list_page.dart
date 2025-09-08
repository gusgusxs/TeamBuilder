import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/team_controller.dart';
import 'team_page.dart';

class TeamListPage extends StatelessWidget {
  const TeamListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TeamController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          c.startNewTeam();                  // สร้างทีมใหม่
          Get.to(() => const TeamPage());    // ไปหน้าแก้ไข (หน้าอื่น)
        },
        icon: const Icon(Icons.add),
        label: const Text('New Team'),
      ),
      body: Obx(() {
        final items = c.teams;
        if (items.isEmpty) {
          return const Center(child: Text('ยังไม่มีทีมที่บันทึก'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final t = items[i];
            return ListTile(
              title: Text(t.name),
              subtitle: Text('สมาชิก: ${t.memberIds.join(", ")}'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon( // ถ้าเวอร์ชันเก่า ใช้ ElevatedButton.icon
                    onPressed: () {
                      c.loadTeamIntoEditor(t.id);         // โหลดข้อมูลทีม
                      Get.to(() => TeamPage(teamId: t.id)); // ➜ ไปหน้าแก้ไข (อีกหน้า)
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('แก้ไข'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete team'),
                          content: Text('ลบทีม "${t.name}" ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) c.deleteTeam(t.id);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('ลบ'),
                  ),
                ],
              ),
              onTap: () {
                // แตะรายการก็ไปหน้าแก้ไขได้เช่นกัน
                c.loadTeamIntoEditor(t.id);
                Get.to(() => TeamPage(teamId: t.id));
              },
            );
          },
        );
      }),
    );
  }
}
