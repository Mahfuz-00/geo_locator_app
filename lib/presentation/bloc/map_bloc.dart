import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/usecases/send_location_usecase.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final SendLocationUseCase sendLocationUseCase;
  Timer? _timer;

  MapBloc({required this.sendLocationUseCase}) : super(MapInitial()) {
    on<StartAutoSendLocation>(_onStartAutoSendLocation);
    on<StopAutoSendLocation>(_onStopAutoSendLocation);
    on<SendLocationNow>(_onSendLocationNow);
  }

  Future<void> _onSendLocationNow(
      SendLocationNow event,
      Emitter<MapState> emit,
      ) async {
    emit(MapLoading());
    try {
      // get current position
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await sendLocationUseCase(pos.latitude, pos.longitude);
      emit(MapSuccess());
    } catch (e) {
      emit(MapError(e.toString()));
    }
  }

  void _onStartAutoSendLocation(
      StartAutoSendLocation event,
      Emitter<MapState> emit,
      ) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      add(SendLocationNow());
    });
  }

  void _onStopAutoSendLocation(
      StopAutoSendLocation event,
      Emitter<MapState> emit,
      ) {
    _timer?.cancel();
    _timer = null;
    emit(MapStopped());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
