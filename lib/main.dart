import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const BlocksterApp());
}

class BlocksterApp extends StatelessWidget {
  const BlocksterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Blockster',
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: mode,
          home: const MenuScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
