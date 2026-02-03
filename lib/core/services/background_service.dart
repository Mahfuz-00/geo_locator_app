import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:get_it/get_it.dart';
import '../../domain/usecases/send_location_usecase.dart';
import '../di/injection.dart';
import '../../core/network/api_client.dart'; // Ensure this is imported

// Global variable to hold the token in the background isolate memory
String? _authToken;

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking',
    description: 'Background Location Tracking Service',
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
      initialNotificationContent: 'Connecting to GPS...',
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
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  DartPluginRegistrant.ensureInitialized();

  if (!GetIt.I.isRegistered<SendLocationUseCase>()) {
    await initGetIt();
  }

  // --- FIX: Listen for token updates from the UI ---
  service.on('updateToken').listen((event) {
    if (event != null && event.containsKey('token')) {
      _authToken = event['token'];

      // Update the ApiClient singleton with the new token
      if (GetIt.I.isRegistered<ApiClient>()) {
        GetIt.I<ApiClient>().manualToken = _authToken;
      }

      print("Background Service: Token updated and injected into ApiClient");
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // --- SLEEP ISSUE FIX: WakeLock Configuration ---
  // Even though we use a Timer, setting this ensures the OS recognizes
  // this as a high-priority background task that needs the CPU alive.
  final AndroidSettings sleepOptimizationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    // WakeLock is the "Secret Sauce" that keeps the CPU hitting the API during sleep
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationText: "Tracking active (Battery Optimized)",
      notificationTitle: "GeoTracker Live",
      enableWakeLock: true,
    ),
  );

  // --- REVERTED TO TIMER (30 SECONDS) ---
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      // --- LOGGED IN CHECK ---
      // 1. CHECK FOR TOKEN BEFORE ANYTHING ELSE
      // FIX: Use the memory variable _authToken instead of storage.read
      if (_authToken == null || _authToken!.isEmpty) {
        print("Background Service: No token found in memory. Skipping ping.");

        // Update notification to show it's idle (optional)
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "GeoTracker: Paused",
            content: "Please log in to resume tracking.",
          );
        }
        return; // EXIT EARLY - NO GPS, NO API
      }

      // FIX: Access the Android-specific provider to use 'locationSettings'
      final androidProvider = GeolocatorPlatform.instance as GeolocatorAndroid;

      Position pos = await androidProvider.getCurrentPosition(
        locationSettings: sleepOptimizationSettings,
      );

      final useCase = GetIt.I<SendLocationUseCase>();
      // Use the token for the API call inside the useCase or update your ApiClient to use _authToken
      await useCase(pos.latitude, pos.longitude);

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Live Tracking Active",
          content: "Last sync: ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
        );
      }
    } catch (e) {
      debugPrint("Background Timer Error: $e");
    }
  });

  /* // --- COMMENTED OUT: NEW OPTIMIZED STREAM CODE ---
  // Save this for when you want to switch to distance-based tracking

  final AndroidSettings locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.medium,
    distanceFilter: 20,
    intervalDuration: const Duration(seconds: 15),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationText: "Location tracking is optimized for battery.",
      notificationTitle: "GeoTracker Live",
      enableWakeLock: true,
    ),
  );

  Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position position) async {
    try {
      final useCase = GetIt.I<SendLocationUseCase>();
      await useCase(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Background Sync Error: $e");
    }
  });
  */
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}