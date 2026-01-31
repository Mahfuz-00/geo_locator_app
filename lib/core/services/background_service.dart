import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import '../../domain/usecases/send_location_usecase.dart';
import '../di/injection.dart';

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  // 1. Setup Local Notifications Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking Service',
    description: 'Running in background to track location.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_channel',
      initialNotificationTitle: 'GeoTracker Active',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 1. STOPS THE CRASH: Set foreground immediately before ANY other code
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "GeoTracker Active",
      content: "Initializing...",
    );
  }

  // 2. Now do the heavy lifting
  DartPluginRegistrant.ensureInitialized();

  // 3. Initialize GetIt only if not already there
  if (!GetIt.I.isRegistered<SendLocationUseCase>()) {
    await initGetIt();
  }

  // Listeners...
  service.on('stopService').listen((event) => service.stopSelf());

  // 4. THE TIMER
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      final useCase = GetIt.I<SendLocationUseCase>();
      await useCase(pos.latitude, pos.longitude);

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Live Tracking Active",
          content: "Last sync: ${DateTime.now().hour}:${DateTime.now().minute}",
        );
      }
    } catch (e) {
      debugPrint("Background error: $e");
    }
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}