import 'package:flutter/material.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phishsafe_app/screens/threat_detected_screen.dart'; // ✅ adjust to your actual path

class SimMonitor {
  static const String _simIdKey = 'stored_sim_id';
  static const String _carrierKey = 'stored_carrier';

  static Future<void> checkForSimSwap(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final bool hasPermission = await MobileNumber.hasPhonePermission;
      if (!hasPermission) {
        debugPrint("❌ SIM permission not granted.");
        return;
      }

      final List<SimCard>? simCards = await MobileNumber.getSimCards;

      if (simCards == null || simCards.isEmpty) {
        debugPrint("❌ No SIM cards found.");
        return;
      }

      final currentSimId = simCards.first.slotIndex.toString();
      final currentCarrier = simCards.first.carrierName ?? 'unknown';

      final storedSimId = prefs.getString(_simIdKey);
      final storedCarrier = prefs.getString(_carrierKey);

      if (storedSimId == null || storedCarrier == null) {
        await prefs.setString(_simIdKey, currentSimId);
        await prefs.setString(_carrierKey, currentCarrier);
        debugPrint("✅ Initial SIM info stored");
      } else if (storedSimId != currentSimId || storedCarrier != currentCarrier) {
        debugPrint("⚠️ SIM swap detected!");
        debugPrint("Old SIM ID: $storedSimId → New: $currentSimId");
        debugPrint("Old Carrier: $storedCarrier → New: $currentCarrier");

        // 🔁 Redirect to warning screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ThreatDetectedScreen()),
        );
        return;
      } else {
        debugPrint("✅ SIM verified.");
      }
    } catch (e) {
      debugPrint("❌ SIM Monitor Error: $e");
    }
  }
}
