// lib/app.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pages/team_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pokémon Team Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const TeamPage(),
    );
  }
}
