import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_platform_interface/flutter_background_service_platform_interface.dart';

/// Initializes the background service.
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'phishsafe_channel',
      initialNotificationTitle: 'PhishSafe Active',
      initialNotificationContent: 'Monitoring session threats...',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

/// Entry point for Android/iOS background isolate
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  Timer? timer;

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setAutoStartOnBootMode(true);

    service.setForegroundNotificationInfo(
      title: "PhishSafe Monitoring",
      content: "Scanning for session anomalies...",
    );
  }

  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  timer = Timer.periodic(const Duration(seconds: 10), (_) {
    final now = DateTime.now().toIso8601String();
    service.invoke('update', {
      "timestamp": now,
      "status": "PhishSafe background service running",
    });
  });
}

/// Entry point for iOS background
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
