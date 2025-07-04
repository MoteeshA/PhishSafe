import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BehaviorLogger {
  final String userId;
  final int maxTapCount;
  final List<Map<String, dynamic>> _logs = [];

  int _tapCount = 0;

  BehaviorLogger({required this.userId, this.maxTapCount = 50});

  void logScreenOpen(String screenName) {
    _logs.add({
      'type': 'screen_open',
      'timestamp': DateTime.now().toIso8601String(),
      'screen': screenName,
    });
  }

  void logTap(String screenName) {
    if (_tapCount >= maxTapCount) return;

    _logs.add({
      'type': 'tap',
      'timestamp': DateTime.now().toIso8601String(),
      'screen': screenName,
    });
    _tapCount++;
  }

  void logCustom(String label, Map<String, dynamic> data) {
    _logs.add({
      'type': label,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  String exportAsJson() {
    return jsonEncode({
      'userId': userId,
      'logs': _logs,
      'metadata': {
        'totalEvents': _logs.length,
        'tapEvents': _tapCount,
        'generatedAt': DateTime.now().toIso8601String(),
      }
    });
  }

  Future<String> saveToFile() async {
    try {
      Directory directory;

      if (Platform.isAndroid || Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        directory = Directory.current;
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      final file = File('${directory.path}/behavioral_logs_${userId}_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(exportAsJson());
      return file.path;
    } catch (e) {
      throw Exception('Failed to save logs: $e');
    }
  }

  void clearLogs() {
    _logs.clear();
    _tapCount = 0;
  }

  List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);
}