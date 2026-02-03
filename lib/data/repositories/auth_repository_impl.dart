import '../../domain/entities/center_entity.dart';
import '../../domain/entities/register_request_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';
import '../sources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<Map<String, dynamic>> login(String username, String password) => dataSource.login(username, password);

  @override
  Future<void> logout() => dataSource.logout();

  @override
  Future<void> register(RegisterRequestEntity data) {
    // Convert Entity to Model (which has the toJson method)
    final model = RegisterRequestModel.fromEntity(data);
    return dataSource.register(model.toJson());
  }

  @override
  Future<List<CenterEntity>> getCenters() => dataSource.getCenters();

  @override
  Future<UserProfileModel> getProfile() => dataSource.getProfile();
}