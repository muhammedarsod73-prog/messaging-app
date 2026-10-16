import 'package:flutter/material.dart';
void main()=>runApp(MaterialApp(home: KingChat()));

class KingChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('King Chat 👑'), backgroundColor: Color(0xFF075E54)),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.crown, size: 80, color: Colors.amber),
        SizedBox(height: 20),
        Text('King Chat Ready!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('All Features Coming...'),
      ])),
    );
  }
}
