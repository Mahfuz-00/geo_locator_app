part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object> get props => [];
}

class CheckAuth extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;
  const LoginEvent(this.username, this.password);
  @override List<Object> get props => [username, password];
}

class LogoutEvent extends AuthEvent {}

class LoadProfile extends AuthEvent {}