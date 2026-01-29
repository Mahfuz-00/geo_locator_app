import 'package:http/http.dart' as http;
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

abstract class LocationRemoteDataSource {
  Future<void> sendLocation(double lat, double lng);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final ApiClient client;

  LocationRemoteDataSourceImpl({required this.client});

  @override
  Future<void> sendLocation(double lat, double lng) async {
    print('Path: $locationEndpoint');
    print('latitude: $lat, longitude: $lng');
    await client.post(
      locationEndpoint,
      {'latitude': lat, 'longitude': lng},
    );
  }
}