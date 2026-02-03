import '../entities/center_entity.dart';
import '../repositories/auth_repository.dart';

class GetCentersUseCase {
  final AuthRepository repository;
  GetCentersUseCase(this.repository);
  Future<List<CenterEntity>> call() => repository.getCenters();
}