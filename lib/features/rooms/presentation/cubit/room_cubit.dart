import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/room_repository.dart';
import 'room_state.dart';

class RoomCubit extends Cubit<RoomState> {
  RoomCubit(this._repository) : super(const RoomState());

  final RoomRepository _repository;

  Future<void> loadRooms(String? ownerId) async {
    if (ownerId == null || ownerId.isEmpty) {
      emit(const RoomState());
      return;
    }

    emit(RoomState(isLoadingRooms: true, rooms: state.rooms));
    try {
      final rooms = await _repository.getRooms(ownerId);
      emit(RoomState(rooms: rooms));
    } on RoomFailure catch (error) {
      emit(RoomState(rooms: state.rooms, roomsErrorMessage: error.message));
    } catch (_) {
      emit(
        RoomState(
          rooms: state.rooms,
          roomsErrorMessage: 'Unable to load rooms.',
        ),
      );
    }
  }

  Future<void> createRoom({
    required String ownerId,
    required String name,
    required String currency,
  }) async {
    if (state.isLoading) return;

    emit(RoomState(isLoading: true, rooms: state.rooms));
    try {
      final room = await _repository.createRoom(
        ownerId: ownerId,
        name: name,
        currency: currency,
      );
      final rooms = [
        ...state.rooms.where((savedRoom) => savedRoom.id != room.id),
        room,
      ];
      emit(RoomState(rooms: rooms, createdRoom: room));
    } on RoomFailure catch (error) {
      emit(RoomState(rooms: state.rooms, errorMessage: error.message));
    } catch (_) {
      emit(
        RoomState(rooms: state.rooms, errorMessage: 'Unable to create room.'),
      );
    }
  }
}
