import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../bloc/auth_bloc.dart';
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
  bool _isInitialCentering = true;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructions();
    });

    controller = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );

    _initLocationTracking();
    context.read<MapBloc>().add(StartAutoSendLocation());
  }

  Future<void> _showInstructions({bool forceShow = false}) async {
    final String? hasSeenStr =
    await _storage.read(key: 'has_seen_instructions');
    final bool hasSeenInstructions = hasSeenStr == 'true';

    if (hasSeenInstructions && !forceShow) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF007930)),
              SizedBox(width: 10),
              Text("ব্যবহার নির্দেশিকা",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• নিরবিচ্ছিন্ন ট্র্যাকিংয়ের জন্য লগ-ইন অবস্থায় থাকুন।"),
              SizedBox(height: 10),
              Text("• কাজ শেষ হলে ব্যাটারি বাঁচাতে লগ-আউট করুন।"),
              SizedBox(height: 10),
              Text(
                  "• সঠিক ট্র্যাকিংয়ের জন্য ফোন স্লিপ মোডে থাকলেও অ্যাপটি ব্যাকগ্রাউন্ডে সচল রাখুন।"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _storage.write(
                    key: 'has_seen_instructions', value: 'true');
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text(
                "ঠিক আছে",
                style: TextStyle(
                    color: Color(0xFF007930),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
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

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((pos) async {
          final geoPoint =
          GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
          _updateTrail(geoPoint);
        });
  }

  Future<void> _updateTrail(GeoPoint pos) async {
    if (!mounted || !_isMapReady) return;

    recentPositions.add(pos);
    if (recentPositions.length > maxPositions) {
      recentPositions.removeAt(0);
    }

    if (recentPositions.length < 2) return;

    try {
      await controller.removeLastRoad();
      await controller.drawRoadManually(
        recentPositions,
        RoadOption(
          roadColor: Colors.blueAccent,
          roadWidth: 6,
          zoomInto: false,
        ),
      );
    } catch (e) {
      debugPrint("Road draw error: $e");
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
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF007930).withOpacity(0.9),
          elevation: 4,
          title: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String districtName = "নির্বাচন কমিশন ট্র্যাকার";
              if (state is AuthAuthenticated) {
                districtName = state.districtName;
              }
              return Row(
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Government_Seal_of_Bangladesh.svg/1200px-Government_Seal_of_Bangladesh.svg.png',
                    height: 35,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      districtName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Noto Serif Bengali',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon:
              const Icon(Icons.help_outline, color: Colors.white, size: 26),
              onPressed: () => _showInstructions(forceShow: true),
            ),
            IconButton(
              icon:
              const Icon(Icons.person_outline, color: Colors.white, size: 28),
              onPressed: () => context.push('/profile'),
            ),
            const SizedBox(width: 8),
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
                      color: Color(0xFF0BBCD9),
                      size: 60,
                    ),
                  ),
                  directionArrowMarker: const MarkerIcon(
                    icon: Icon(
                      Icons.navigation_rounded,
                      color: Color(0xFF007930),
                      size: 60,
                    ),
                  ),
                ),
              ),
              onMapIsReady: (ready) async {
                if (ready) {
                  setState(() => _isMapReady = true);

                  GeoPoint myLoc = await controller.myLocation();
                  await controller.moveTo(myLoc, animate: false);
                  await controller.setZoom(zoomLevel: 17);
                  await controller.enableTracking(enableStopFollow: false);

                  if (mounted) {
                    setState(() => _isInitialCentering = false);
                  }
                }
              },
              onLocationChanged: (userLocation) {
                _updateTrail(userLocation);
              },
            ),

            if (_isInitialCentering)
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Color(0xFF007930)),
                    SizedBox(height: 20),
                    Text("ম্যাপ লোড হচ্ছে..."),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "recenter",
          backgroundColor: const Color(0xFF007930),
          onPressed: () async {
            GeoPoint myLoc = await controller.myLocation();
            await controller.moveTo(myLoc, animate: true);
            await controller.setZoom(zoomLevel: 17);
          },
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
    );
  }
}
