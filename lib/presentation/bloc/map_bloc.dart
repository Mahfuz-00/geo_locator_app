import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/usecases/send_location_usecase.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final SendLocationUseCase sendLocationUseCase;

  MapBloc({required this.sendLocationUseCase}) : super(MapInitial()) {
    on<StartAutoSendLocation>(_onStartAutoSendLocation);
    on<StopAutoSendLocation>(_onStopAutoSendLocation);
    on<SendLocationNow>(_onSendLocationNow);
  }

  // Use this for manual "Send Now" button or internal UI updates
  Future<void> _onSendLocationNow(SendLocationNow event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await sendLocationUseCase(pos.latitude, pos.longitude);
      emit(MapSuccess());
    } catch (e) {
      emit(MapError(e.toString()));
    }
  }

  // Tells the NATIVE BACKGROUND SERVICE to start
  void _onStartAutoSendLocation(StartAutoSendLocation event, Emitter<MapState> emit) async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
    emit(MapSuccess());
  }

  // Tells the NATIVE BACKGROUND SERVICE to stop
  void _onStopAutoSendLocation(StopAutoSendLocation event, Emitter<MapState> emit) async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    emit(MapStopped());
  }
}