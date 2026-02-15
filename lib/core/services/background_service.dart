import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:get_it/get_it.dart';
import '../../domain/usecases/send_location_usecase.dart';
import '../di/injection.dart';
import '../../core/network/api_client.dart';

// Global variable to hold the token in the background isolate memory
String? _authToken;

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('ec_logo');

  await flutterLocalNotificationsPlugin.initialize(
    settings: InitializationSettings(android: initializationSettingsAndroid),
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking',
    description: 'Background Location Tracking Service',
    importance: Importance.low,
  );

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
      initialNotificationTitle: 'EC Tracker Active',
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
    // FIX: Using listen to handle foreground transitions safely
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.setAsForegroundService();
  }

  DartPluginRegistrant.ensureInitialized();

  if (!GetIt.I.isRegistered<SendLocationUseCase>()) {
    await initGetIt();
  }

  final storage = const FlutterSecureStorage();
  _authToken = await storage.read(key: 'token');
  if (_authToken != null && GetIt.I.isRegistered<ApiClient>()) {
    GetIt.I<ApiClient>().manualToken = _authToken;
    print("✅ Background Service: Token recovered from storage on startup");
  }

  // --- FIX: Listen for token updates from the UI ---
  service.on('updateToken').listen((event) {
    if (event != null && event.containsKey('token')) {
      _authToken = event['token'];

      // Update the ApiClient singleton with the new token
      if (GetIt.I.isRegistered<ApiClient>()) {
        GetIt.I<ApiClient>().manualToken = _authToken;
      }

      print("✅ Background Service: Isolate received NEW token from UI");
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
      notificationText: "Tracking active",
      notificationTitle: "EC Tracker Live",
      enableWakeLock: true,
    ),
  );

  // --- REVERTED TO TIMER (30 SECONDS) ---
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      // --- LOGGED IN CHECK ---
      // --- SECTION 1: INTERNET CONNECTION CHECK ---
      // FIX: সরাসরি DNS Lookup করা হচ্ছে যা ওয়াইফাই থাকলেও ইন্টারনেট আছে কি না তা নিশ্চিত করবে।
      bool hasInternet = false;
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          hasInternet = true;
        }
      } catch (_) {
        hasInternet = false;
      }

      if (!hasInternet) {
        debugPrint("📡 Background Service: No Internet. Waiting for connection...");
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "EC Tracker: Offline",
            content: "Waiting for internet connection...",
          );
        }
        return; // ইন্টারনেট না থাকলে পরবর্তী কোড এক্সিকিউট হবে না
      }


      // 2. CHECK FOR TOKEN BEFORE ANYTHING ELSE
      // FIX: Use the memory variable _authToken instead of storage.read
      if (_authToken == null || _authToken!.isEmpty) {
        _authToken = await storage.read(key: 'token');
        if (_authToken != null && GetIt.I.isRegistered<ApiClient>()) {
          GetIt.I<ApiClient>().manualToken = _authToken;
        }
      }

      if (_authToken == null || _authToken!.isEmpty) {
        debugPrint("⚠️ Background Service: No token found. Skipping ping.");
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "EC Tracker: Paused",
            content: "Waiting for login...",
          );
        }
        return;
      }

      // --- SECTION 3: GPS & API SYNC ---
      // FIX: Use parameters directly if your version doesn't support locationSettings object
      // or use the static method to avoid isolate-specific casting errors
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
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