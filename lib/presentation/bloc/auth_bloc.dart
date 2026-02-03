import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geo_tracker_app/domain/usecases/register_usecase.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/usecases/get_profile_usecase.dart';
import '../../../core/constants/app_constants.dart';
import '../../domain/entities/center_entity.dart';
import '../../domain/entities/register_request_entity.dart';
import '../../domain/usecases/get_centers_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetProfileUseCase getProfileUseCase;
  final GetCentersUseCase getCentersUseCase;
  final RegisterUseCase registerUseCase;

  // Use storage to persist district_name across app restarts
  final _storage = const FlutterSecureStorage();

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getProfileUseCase,
    required this.registerUseCase,
    required this.getCentersUseCase,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuth>(_onCheckAuth);
    on<LoadProfile>(_onLoadProfile);
    on<LoadCenters>(_onLoadCenters);
    on<RegisterUser>(_onRegister);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // The login response contains: token, district_name, and user object
      final response = await loginUseCase(event.username, event.password);

      // 1. Extract district_name from the top level of the login response
      final district = response['district_name']?.toString() ?? "নির্বাচন কমিশন ট্র্যাকার";

      // 2. Persist district to storage so CheckAuth can find it later
      await _storage.write(key: 'district_name', value: district);

      emit(AuthAuthenticated(districtName: district));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuth(CheckAuth event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Check if we have a saved token
      final token = await _storage.read(key: tokenKey);

      if (token != null && token.isNotEmpty) {
        // Optional: Verify session is still valid by calling profile
        await getProfileUseCase();

        // Retrieve the persisted district name
        final district = await _storage.read(key: 'district_name') ?? "নির্বাচন কমিশন ট্র্যাকার";

        emit(AuthAuthenticated(districtName: district));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      // If token is invalid or network fails during check, logout
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoadCenters(LoadCenters event, Emitter<AuthState> emit) async {
    try {
      final centers = await getCentersUseCase();

      // Logging individual names to verify parsing
      for (var center in centers) {
        print('Parsed Center: ${center.name} (ID: ${center.id})');
      }

      emit(CentersLoaded(centers));
    } catch (e) {
      emit(AuthError("সেন্টার লোড করা সম্ভব হয়নি"));
    }
  }

  Future<void> _onRegister(RegisterUser event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await registerUseCase(event.request);
      emit(RegisterSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // getProfileUseCase now returns a UserEntity instead of a Map
      final UserProfileEntity profile = await getProfileUseCase();
      emit(AuthProfileLoaded(profile));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await logoutUseCase();

      // Clear specific auth-related stored data
      await _storage.delete(key: 'district_name');

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}