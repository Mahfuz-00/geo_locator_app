import '../repositories/location_repository.dart';

class SendLocationUseCase {
  final LocationRepository repository;
  SendLocationUseCase(this.repository);
  Future<void> call(double lat, double lng) => repository.sendLocation(lat, lng);
}