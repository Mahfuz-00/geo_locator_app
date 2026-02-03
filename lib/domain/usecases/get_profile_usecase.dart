import 'package:geo_tracker_app/domain/entities/user_entity.dart';

import '../repositories/auth_repository.dart';

class GetProfileUseCase {
  final AuthRepository repository;
  GetProfileUseCase(this.repository);

  Future<UserProfileEntity> call() {
    return repository.getProfile();
  }
}
