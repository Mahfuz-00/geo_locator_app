import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../bloc/map_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late MapController controller;
  final List<GeoPoint> recentPositions = [];
  final int maxPositions = 60;

  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();

    controller = MapController.withUserPosition(
      trackUserLocation: UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );

    _initLocationTracking();

    // Start auto send
    context.read<MapBloc>().add(StartAutoSendLocation());
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) async {
          final geoPoint =
          GeoPoint(latitude: pos.latitude, longitude: pos.longitude);

          _updateTrail(geoPoint);

          // auto center & zoom
          await controller.goToLocation(geoPoint);
          await controller.setZoom(zoomLevel: 17);
        });
  }

  Future<void> _updateTrail(GeoPoint pos) async {
    setState(() {
      recentPositions.add(pos);
      if (recentPositions.length > maxPositions) {
        recentPositions.removeAt(0);
      }
    });

    if (recentPositions.length >= 2) {
      await controller.clearAllRoads();
      await controller.drawRoadManually(
        recentPositions,
        RoadOption(
          roadColor: Colors.blue.withOpacity(0.7),
          roadWidth: 4,
          isDotted: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button closing
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: OSMFlutter(
          controller: controller,
          osmOption: OSMOption(
            zoomOption: const ZoomOption(
              initZoom: 16,
              minZoomLevel: 3,
              maxZoomLevel: 19,
            ),
            userLocationMarker: UserLocationMaker(
              personMarker: const MarkerIcon(
                icon: Icon(Icons.my_location,
                    color: Colors.redAccent, size: 48),
              ),
              directionArrowMarker: const MarkerIcon(
                icon:
                Icon(Icons.navigation_rounded, color: Colors.blue, size: 40),
              ),
            ),
          ),
          onMapIsReady: (ready) async {
            if (ready) {
              await controller.enableTracking(enableStopFollow: false);

              // Center to first location
              await Future.delayed(const Duration(seconds: 2));
              final myLocation = await controller.myLocation();
              if (myLocation != null) {
                await controller.goToLocation(myLocation);
                await controller.setZoom(zoomLevel: 17);
              }
            }
          },
          onLocationChanged: (userLocation) {
            _updateTrail(userLocation);
          },
        ),
      ),
    );
  }
}
