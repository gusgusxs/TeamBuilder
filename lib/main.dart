import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/team_controller.dart';
import 'pages/team_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ ผูก TeamController ตอนเริ่มแอป
      initialBinding: BindingsBuilder(() {
        Get.put(TeamController());
      }),

      // ✅ หน้าแรกเป็น TeamListPage
      home: const TeamListPage(),
    );
  }
}
