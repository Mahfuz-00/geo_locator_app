import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Added for token retrieval
import '../../../domain/usecases/send_location_usecase.dart';
import '../../../core/constants/app_constants.dart'; // Ensure tokenKey is imported

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final SendLocationUseCase sendLocationUseCase;
  final _storage = const FlutterSecureStorage(); // Instance for reading the token

  MapBloc({required this.sendLocationUseCase}) : super(MapInitial()) {
    on<StartAutoSendLocation>(_onStartAutoSendLocation);
    on<StopAutoSendLocation>(_onStopAutoSendLocation);
    on<SendLocationNow>(_onSendLocationNow);
  }

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

  // Updated to pass the token to the background isolate
  void _onStartAutoSendLocation(StartAutoSendLocation event, Emitter<MapState> emit) async {
    final service = FlutterBackgroundService();

    // 1. Fetch the token from the UI Isolate (where it is safe)
    final token = await _storage.read(key: tokenKey);

    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }

    // 2. Wait a moment for service initialization then push the token
    // We invoke 'updateToken' which matches the listener we added in the background file
    service.invoke("updateToken", {
      "token": token,
    });

    emit(MapSuccess());
  }

  void _onStopAutoSendLocation(StopAutoSendLocation event, Emitter<MapState> emit) async {
    final service = FlutterBackgroundService();

    // 3. Clear the token in background memory before stopping for safety
    service.invoke("updateToken", {"token": null});

    service.invoke("stopService");
    emit(MapStopped());
  }
}