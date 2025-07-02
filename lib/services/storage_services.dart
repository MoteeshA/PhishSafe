import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String hesitationKey = 'hesitation_average';

  static Future<void> setHesitationAverage(double avg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(hesitationKey, avg);
  }

  static Future<double?> getHesitationAverage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(hesitationKey);
  }

  // Optional: Add methods for clearing or debugging
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
