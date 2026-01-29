import '../repositories/auth_repository.dart';

class GetProfileUseCase {
  final AuthRepository repository;
  GetProfileUseCase(this.repository);

  Future<Map<String, dynamic>> call() {
    return repository.getProfile();
  }
}
