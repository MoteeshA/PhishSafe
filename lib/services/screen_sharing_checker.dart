import 'package:flutter/services.dart';

class ScreenSharingChecker {
  static const platform = MethodChannel('phishsafe/screen_sharing');

  static Future<bool> isScreenSharing() async {
    try {
      final result = await platform.invokeMethod<bool>('isScreenSharing');
      return result ?? false;
    } catch (e) {
      print("Error checking screen sharing: $e");
      return false;
    }
  }
}
