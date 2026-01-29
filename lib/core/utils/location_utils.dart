import 'package:geolocator/geolocator.dart';

Future<Position?> getCurrentPosition() async {
  bool service = await Geolocator.isLocationServiceEnabled();
  if (!service) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }

  if (permission == LocationPermission.deniedForever) return null;

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}