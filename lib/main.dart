import 'package:flutter/material.dart';
import 'screens/menu_screen_doc.dart';

void main() {
  runApp(const BlocksterApp());
}

class BlocksterApp extends StatelessWidget {
  const BlocksterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockster',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
