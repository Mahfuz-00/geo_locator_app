import '../../domain/repositories/auth_repository.dart';
import '../sources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<String> login(String username, String password) => dataSource.login(username, password);

  @override
  Future<void> logout() => dataSource.logout();

  @override
  Future<Map<String, dynamic>> getProfile() => dataSource.getProfile();
}