import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PoGetItApp());
}

class PoGetItApp extends StatelessWidget {
  const PoGetItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PoGetIt Quest Prototypes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
