import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _isMapReady = false;

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
    context.read<MapBloc>().add(StartAutoSendLocation());
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;
    }

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // For Background (Always) tracking
    if (permission == LocationPermission.whileInUse) {
      // This will prompt for 'Always Allow' on Android
      permission = await Geolocator.requestPermission();
    }

    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((pos) async {
          final geoPoint = GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
          _updateTrail(geoPoint);
        });
  }

  Future<void> _updateTrail(GeoPoint pos) async {
    if (!mounted) return;
    setState(() {
      recentPositions.add(pos);
      if (recentPositions.length > maxPositions) {
        recentPositions.removeAt(0);
      }
    });

    if (recentPositions.length >= 2 && _isMapReady) {
      try {
        await controller.clearAllRoads();
        await controller.drawRoadManually(
          recentPositions,
          RoadOption(
            roadColor: Colors.blueAccent,
            roadWidth: 8,
            zoomInto: false, // Don't snap zoom every time point is added
          ),
        );
      } catch (e) {
        debugPrint("Error drawing road: $e");
      }
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
    return PopScope(
      canPop: false, // Modern replacement for WillPopScope
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          // --- Updated AppBar with Figma Logo ---
          automaticallyImplyLeading: false, // Removes default back button if any
          title: Container(
            width: 109, // Figma width
            height: 46, // Figma height
            margin: const EdgeInsets.only(left: 4), // Aligned to Figma 'left: 16px' roughly
            child: Image.asset(
              'assets/images/district-logo.png',
              fit: BoxFit.contain,
            ),
          ),
          backgroundColor: Colors.black.withOpacity(0.3),
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 10), // Adjusting to match 'top: 69px' logic
              child: GestureDetector(
                onTap: () => context.push('/profile'),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            OSMFlutter(
              controller: controller,
              osmOption: OSMOption(
                userTrackingOption: const UserTrackingOption(
                  enableTracking: true,
                  unFollowUser: false,
                ),
                zoomOption: const ZoomOption(
                  initZoom: 17,
                  minZoomLevel: 3,
                  maxZoomLevel: 19,
                ),
                userLocationMarker: UserLocationMaker(
                  personMarker: const MarkerIcon(
                    icon: Icon(
                      Icons.location_history_rounded,
                      color: Colors.redAccent,
                      size: 60, // Larger user marker
                    ),
                  ),
                  directionArrowMarker: const MarkerIcon(
                    icon: Icon(
                      Icons.navigation_rounded,
                      color: Colors.blueAccent,
                      size: 60, // Directional arrow
                    ),
                  ),
                ),
                roadConfiguration: const RoadOption(
                  roadColor: Colors.blueAccent,
                  roadWidth: 10,
                ),
              ),
              onMapIsReady: (ready) async {
                if (ready) {
                  setState(() => _isMapReady = true);
                  await controller.enableTracking(enableStopFollow: false);
                }
              },
              onLocationChanged: (userLocation) {
                _updateTrail(userLocation);
              },
            ),

            // UI Overlay: Status Badge
            Positioned(
              top: 100,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      "Live Tracking Active",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "recenter",
              backgroundColor: Colors.white,
              onPressed: () async {
                try {
                  // 1. Get current location from the controller
                  GeoPoint myLoc = await controller.myLocation();

                  // 2. Move to the location
                  await controller.moveTo(myLoc, animate: true);

                  // 3. Small delay to let the animation finish and the map settle
                  await Future.delayed(const Duration(milliseconds: 350));

                  // 4. Match your exact parameter names from the source code
                  await controller.enableTracking(
                    enableStopFollow: false,
                    useDirectionMarker: true, // Set to true if you want the arrow icon
                    anchor: Anchor.center,
                  );

                  // 5. Re-apply zoom to ensure we are at the right level
                  await controller.setZoom(zoomLevel: 17);

                } catch (e) {
                  debugPrint("Recenter error: $e");
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blueAccent),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}