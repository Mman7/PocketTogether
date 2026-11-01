import '../../models/room_activity.dart';

class RoomActivityState {
  const RoomActivityState({
    this.items = const [],
    this.filter = RoomActivityFilter.all,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  final List<RoomActivity> items;
  final RoomActivityFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;

  RoomActivityState copyWith({
    List<RoomActivity>? items,
    RoomActivityFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RoomActivityState(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
