import '../../domain/repositories/location_repository.dart';
import '../sources/location_remote_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource dataSource;

  LocationRepositoryImpl(this.dataSource);

  @override
  Future<void> sendLocation(double lat, double lng) => dataSource.sendLocation(lat, lng);
}