import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/decryption_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DecryptionService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NPS Browser',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
