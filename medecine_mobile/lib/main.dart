import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MedecineApp());
}

class MedecineApp extends StatelessWidget {
  const MedecineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assistant Médical',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
