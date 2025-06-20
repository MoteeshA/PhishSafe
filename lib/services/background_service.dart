import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

/// Initializes the background service.
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'phishsafe_channel',
      initialNotificationTitle: 'PhishSafe Monitoring Active',
      initialNotificationContent: 'Watching for session threats...',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

/// Background task logic
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  // Timer reference so we can cancel it when service is stopped
  Timer? timer;

  // Listen for stop requests from main app
  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  // Trigger initial events if needed
  service.invoke('update');
  service.invoke('checkThreats');

  // ✅ Start periodic background task
  timer = Timer.periodic(const Duration(seconds: 5), (_) {
    // Show foreground notification (Android)
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "PhishSafe Running",
        content: "Monitoring session threats in real-time",
      );
    }

    // Background monitoring logic here
    debugPrint('✅ PhishSafe background task running: ${DateTime.now()}');
  });
}

/// iOS background entry point
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
