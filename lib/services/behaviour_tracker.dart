import 'package:flutter/material.dart';
import 'storage_services.dart'; // ✅ Corrected relative import

class BehaviorTracker {
  static const double hesitationThreshold = 1.5; // seconds

  /// Call this from HesitationButton
  static Future<void> logHesitation(Duration hesitation) async {
    double hesitationSeconds = hesitation.inMilliseconds / 1000;

    double? avg = await StorageService.getHesitationAverage();

    if (avg == null || avg == 0.0) {
      // First time: store it
      await StorageService.setHesitationAverage(hesitationSeconds);
      debugPrint("✅ Stored initial hesitation: $hesitationSeconds s");
    } else {
      // Compare and flag if suspicious
      double diff = (hesitationSeconds - avg).abs();
      if (diff > hesitationThreshold) {
        debugPrint("⚠️ Suspicious hesitation detected: $hesitationSeconds s (avg: $avg s)");
        // TODO: Trigger flag UI or secure action
      }

      // Update average with exponential moving average (EMA)
      double newAvg = (avg * 0.9) + (hesitationSeconds * 0.1);
      await StorageService.setHesitationAverage(newAvg);
      debugPrint("🔄 Updated hesitation avg: $newAvg");
    }
  }
}

