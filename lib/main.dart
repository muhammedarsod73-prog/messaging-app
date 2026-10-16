import 'package:flutter/material.dart';

void main() {
  runApp(const KingChatApp());
}

class KingChatApp extends StatelessWidget {
  const KingChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'King Chat',
      debugShowCheckedModeBanner: false,
      home: const KingChatHome(),
    );
  }
}

class KingChatHome extends StatelessWidget {
  const KingChatHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B0082),
        title: const Text('King Chat',
            style: TextStyle(color: Color(0xFFFFD700))),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4B0082),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('K',
                    style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 80,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('King Chat',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B0082))),
          ],
        ),
      ),
    );
  }
}
