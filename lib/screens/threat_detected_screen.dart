import 'package:flutter/material.dart';

class ThreatDetectedScreen extends StatelessWidget {
  const ThreatDetectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            const Text(
              "Threat Detected!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text(
              "Screen sharing is active.\nYour session has been flagged.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
