import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/room_repository.dart';
import '../../models/room.dart';
import '../../models/room_operation_result.dart';
import 'room_state.dart';

class RoomCubit extends Cubit<RoomState> {
  RoomCubit(this._repository) : super(const RoomState());

  final RoomRepository _repository;
  StreamSubscription<List<Room>>? _roomsSubscription;
  String? _watchedUserId;

  Future<void> loadRooms(String? userId) async {
    if (userId == null || userId.isEmpty) {
      await _roomsSubscription?.cancel();
      _roomsSubscription = null;
      _watchedUserId = null;
      if (!isClosed) emit(const RoomState());
      return;
    }

    if (_watchedUserId == userId && _roomsSubscription != null) return;
    await _roomsSubscription?.cancel();
    _watchedUserId = userId;
    emit(state.copyWith(isLoadingRooms: true, clearRoomsErrorMessage: true));
    try {
      _roomsSubscription = _repository
          .watchMyRooms(userId)
          .listen(
            (rooms) {
              if (!isClosed) {
                emit(
                  state.copyWith(
                    isLoadingRooms: false,
                    rooms: rooms,
                    clearRoomsErrorMessage: true,
                  ),
                );
              }
            },
            onError: (Object error) {
              if (!isClosed) {
                emit(
                  state.copyWith(
                    isLoadingRooms: false,
                    roomsErrorMessage: error is RoomFailure
                        ? error.message
                        : 'Unable to load rooms.',
                  ),
                );
              }
            },
          );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingRooms: false,
          roomsErrorMessage: 'Unable to load rooms.',
        ),
      );
    }
  }

  Future<void> createRoom({
    required String name,
    required String currency,
  }) async {
    if (state.isLoading || state.isJoining) return;

    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        clearCreatedRoom: true,
      ),
    );
    try {
      print('launch createRoom');
      final result = await _repository.createRoom(
        name: name,
        currency: currency,
      );
      print('createdRoom result: $result');
      if (isClosed) return;
      final rooms = [
        ...state.rooms.where((savedRoom) => savedRoom.id != result.room.id),
        result.room,
      ];
      emit(state.copyWith(isLoading: false, rooms: rooms, createdRoom: result));
    } on RoomFailure catch (error) {
      if (!isClosed) {
        debugPrint(
          'createRoom failed: code=${error.code ?? 'unknown'} message=${error.message}',
        );
        emit(state.copyWith(isLoading: false, errorMessage: error.message));
      }
    } catch (error, stackTrace) {
      debugPrint('createRoom failed unexpectedly: $error\n$stackTrace');
      if (!isClosed) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Unable to create room.',
          ),
        );
      }
    }
  }

  Future<RoomJoinResult?> joinRoom({required String inviteCode}) async {
    if (state.isLoading || state.isJoining) return null;

    emit(
      state.copyWith(
        isJoining: true,
        clearJoinErrorMessage: true,
        clearJoinedRoom: true,
      ),
    );
    try {
      final result = await _repository.joinRoom(inviteCode: inviteCode);
      if (isClosed) return null;
      emit(state.copyWith(isJoining: false, joinedRoom: result));
      return result;
    } on RoomFailure catch (error) {
      if (!isClosed) {
        emit(state.copyWith(isJoining: false, joinErrorMessage: error.message));
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isJoining: false,
            joinErrorMessage: 'Unable to join this room. Please try again.',
          ),
        );
      }
    }
    return null;
  }

  void clearJoinError() {
    if (state.joinErrorMessage != null) {
      emit(state.copyWith(clearJoinErrorMessage: true));
    }
  }

  @override
  Future<void> close() async {
    await _roomsSubscription?.cancel();
    await super.close();
  }
}
