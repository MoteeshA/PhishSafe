import 'package:flutter/material.dart';
import 'dart:io';

class ThreatDetectedScreen extends StatelessWidget {
  const ThreatDetectedScreen({super.key});

  void _exitApp() {
    exit(0); // Force closes the app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 100, color: Colors.yellowAccent),
              const SizedBox(height: 30),
              const Text(
                'Security Alert',
                style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Potential SIM swap detected.\nFor your safety, the app is now locked.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _exitApp,
                icon: const Icon(Icons.logout),
                label: const Text("Exit App"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
