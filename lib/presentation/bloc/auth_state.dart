part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String districtName;
  const AuthAuthenticated({required this.districtName});

  @override
  List<Object?> get props => [districtName];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object> get props => [message];
}

class AuthProfileLoaded extends AuthState {
  final UserProfileEntity profile;
  const AuthProfileLoaded(this.profile);
  @override List<Object> get props => [profile];
}

class RegisterSuccess extends AuthState {}

class CentersLoaded extends AuthState {
  final List<CenterEntity> centers;
  const CentersLoaded(this.centers);
  @override List<Object?> get props => [centers];
}