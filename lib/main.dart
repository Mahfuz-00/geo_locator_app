import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geo_tracker_app/core/services/background_service.dart';
import 'package:geo_tracker_app/presentation/bloc/map_bloc.dart';
import 'package:get_it/get_it.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/config/routes/app_router.dart';
import 'presentation/bloc/auth_bloc.dart';

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'location_channel',
    'Location Tracking Service',
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await initGetIt();

  // FIX: Ensure the notification channel is fully committed before starting service
  Future.delayed(const Duration(milliseconds: 500), () async {
    await initBackgroundService();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.I<AuthBloc>()..add(CheckAuth())),
        BlocProvider(create: (_) => GetIt.I<MapBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Geo Locator',
        debugShowMaterialGrid: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}