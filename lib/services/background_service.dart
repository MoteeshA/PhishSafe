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
      initialNotificationTitle: 'PhishSafe Protection Active',
      initialNotificationContent: 'Monitoring for security threats',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

/// Background service entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "PhishSafe Protection",
      content: "Active threat monitoring",
    );
  }

  Timer? timer;

  // Handle service control messages
  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  // Main monitoring loop
  timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "PhishSafe Running",
        content: "Last checked: ${DateTime.now().toLocal()}",
      );
    }

    // ✅ Only background-appropriate checks here
    debugPrint('🔒 Security check at ${DateTime.now()}');

    // Add other background-compatible threat checks here
    // (e.g., network monitoring, but NOT platform channels)
  });
}

/// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}