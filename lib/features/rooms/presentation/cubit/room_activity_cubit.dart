import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/room_activity_repository.dart';
import '../../models/room_activity.dart';
import 'room_activity_state.dart';

/// Coordinates filtered, cursor-paginated activity loading for one room.
///
/// Each new load increments [_requestVersion]. Responses from an older filter
/// or refresh are ignored so a slower request cannot replace newer state.
class RoomActivityCubit extends Cubit<RoomActivityState> {
  RoomActivityCubit(this._repository) : super(const RoomActivityState());

  final RoomActivityRepository _repository;
  String? _roomId;
  int _requestVersion = 0;

  Future<void> load(
    String roomId, {
    RoomActivityFilter filter = RoomActivityFilter.all,
  }) async {
    // Reset the page when the room or filter changes; pagination belongs to
    // the specific query represented by the current state.
    final requestVersion = ++_requestVersion;
    _roomId = roomId;
    emit(RoomActivityState(filter: filter, isLoading: true, hasMore: true));
    await _fetchFirstPage(roomId, filter, requestVersion);
  }

  Future<void> changeFilter(RoomActivityFilter filter) async {
    final roomId = _roomId;
    if (roomId == null || filter == state.filter && state.isLoading) return;
    await load(roomId, filter: filter);
  }

  Future<void> refresh() async {
    final roomId = _roomId;
    if (roomId == null) return;
    await load(roomId, filter: state.filter);
  }

  Future<void> loadMore() async {
    final roomId = _roomId;
    if (roomId == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.items.isEmpty) {
      return;
    }

    // Keep the request version stable for this page so a concurrent refresh
    // can invalidate the response without cancelling the underlying Future.
    final requestVersion = _requestVersion;
    emit(state.copyWith(isLoadingMore: true, clearErrorMessage: true));
    try {
      final page = await _repository.getPage(
        roomId: roomId,
        after: state.items.last,
        filter: state.filter,
      );
      if (isClosed || requestVersion != _requestVersion) return;
      final existingIds = state.items.map((item) => item.id).toSet();
      final items = [
        ...state.items,
        ...page.items.where((item) => existingIds.add(item.id)),
      ];
      emit(
        state.copyWith(
          items: items,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } on RoomActivityFailure catch (error) {
      if (!isClosed && requestVersion == _requestVersion) {
        emit(state.copyWith(isLoadingMore: false, errorMessage: error.message));
      }
    } catch (_) {
      if (!isClosed && requestVersion == _requestVersion) {
        emit(
          state.copyWith(
            isLoadingMore: false,
            errorMessage: 'Unable to load room activity.',
          ),
        );
      }
    }
  }

  Future<void> _fetchFirstPage(
    String roomId,
    RoomActivityFilter filter,
    int requestVersion,
  ) async {
    try {
      final page = await _repository.getPage(roomId: roomId, filter: filter);
      if (isClosed || requestVersion != _requestVersion) return;
      emit(
        RoomActivityState(
          items: page.items,
          filter: filter,
          hasMore: page.hasMore,
        ),
      );
    } on RoomActivityFailure catch (error) {
      if (!isClosed && requestVersion == _requestVersion) {
        emit(RoomActivityState(filter: filter, errorMessage: error.message));
      }
    } catch (_) {
      if (!isClosed && requestVersion == _requestVersion) {
        emit(
          const RoomActivityState(
            errorMessage: 'Unable to load room activity.',
          ),
        );
      }
    }
  }
}
