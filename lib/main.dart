import 'package:flutter/material.dart';
import 'package:phishsafe_app/screens/home_screen.dart';
import 'package:phishsafe_app/services/background_service.dart';
import 'package:phishsafe_app/services/sim_monitor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService(); // ✅ Start background service
  runApp(const PhishSafeApp());
}

class PhishSafeApp extends StatelessWidget {
  const PhishSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SimMonitor.checkForSimSwap(context); // ✅ Run SIM check safely after first frame
    });

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
