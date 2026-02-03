import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../data/sources/auth_remote_datasource.dart';
import '../../data/sources/location_remote_datasource.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_centers_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/send_location_usecase.dart';
import '../../presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/map_bloc.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> initGetIt() async {
  // blocs
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    logoutUseCase: sl(),
    getProfileUseCase: sl(),
    registerUseCase: sl(),
    getCentersUseCase: sl(),
  ));
  sl.registerFactory(() => MapBloc(sendLocationUseCase: sl()));

  // usecases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => SendLocationUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetCentersUseCase(sl()));

  // repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<LocationRepository>(() => LocationRepositoryImpl(sl()));

  // datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(client: sl()));
  sl.registerLazySingleton<LocationRemoteDataSource>(() => LocationRemoteDataSourceImpl(client: sl()));

  // external
  sl.registerLazySingleton(() => http.Client());

  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));
}