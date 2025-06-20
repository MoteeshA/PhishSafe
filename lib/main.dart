import 'package:flutter/material.dart';
import 'package:phishsafe_app/screens/home_screen.dart';
import 'package:phishsafe_app/services/background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService(); // Start the background service
  runApp(const PhishSafeApp());
}

class PhishSafeApp extends StatelessWidget {
  const PhishSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhishSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
