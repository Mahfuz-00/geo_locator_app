import '../entities/register_request_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  // Use Case now accepts the Entity, not a Map
  Future<void> call(RegisterRequestEntity params) => repository.register(params);
}