part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class StartAutoSendLocation extends MapEvent {}

class StopAutoSendLocation extends MapEvent {}

class SendLocationNow extends MapEvent {}
