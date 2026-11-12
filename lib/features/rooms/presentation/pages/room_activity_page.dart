import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timelines_plus/timelines_plus.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../shared/presentation/money_format.dart';
import '../../../../shared/presentation/widgets/ambient_background.dart';
import '../../../../shared/presentation/widgets/flow_widgets.dart';
import '../../data/room_activity_repository.dart';
import '../../models/room.dart';
import '../../models/room_activity.dart';
import '../../models/room_member.dart';
import '../cubit/room_activity_cubit.dart';
import '../cubit/room_activity_state.dart';

/// Displays a room's filtered activity timeline with pull-to-refresh and
/// cursor pagination.
///
/// The page owns the Cubit and scroll controller because both are scoped to
/// this room screen and must be disposed together when the route closes.
class RoomActivityPage extends StatefulWidget {
  const RoomActivityPage({
    required this.room,
    required this.members,
    required this.repository,
    super.key,
  });

  final Room room;
  final List<RoomMember> members;
  final RoomActivityRepository repository;

  @override
  State<RoomActivityPage> createState() => _RoomActivityPageState();
}

class _RoomActivityPageState extends State<RoomActivityPage> {
  final _scrollController = ScrollController();
  late final RoomActivityCubit _cubit;

  Map<String, String> get _names => {
    for (final member in widget.members) member.userId: member.displayName,
  };

  @override
  void initState() {
    super.initState();
    _cubit = RoomActivityCubit(widget.repository)..load(widget.room.id);
    _scrollController.addListener(_loadWhenNearEnd);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadWhenNearEnd)
      ..dispose();
    _cubit.close();
    super.dispose();
  }

  void _loadWhenNearEnd() {
    // Load before the viewport reaches the end so the footer rarely becomes
    // the only visible content while the next page is being fetched.
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 320) {
      _cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AmbientBackground(
        child: Scaffold(
          appBar: AppBar(title: const Text('Activity')),
          body: BlocBuilder<RoomActivityCubit, RoomActivityState>(
            builder: (context, state) => Column(
              children: [
                _FilterBar(
                  selected: state.filter,
                  onSelected: context.read<RoomActivityCubit>().changeFilter,
                ),
                Expanded(child: _buildContent(context, state)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RoomActivityState state) {
    final cubit = context.read<RoomActivityCubit>();
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty && state.errorMessage != null) {
      return _ErrorView(message: state.errorMessage!, onRetry: cubit.refresh);
    }
    if (state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: SizedBox(
          width: double.infinity,
          child: EmptyState(
            title: 'No activity yet',
            message: 'Room updates will appear here.',
          ),
        ),
      );
    }

    final hasFooter =
        state.isLoadingMore || state.hasMore || state.errorMessage != null;
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: Timeline.tileBuilder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        builder: TimelineTileBuilder(
          itemCount: state.items.length + (hasFooter ? 1 : 0),
          contentsBuilder: (_, index) {
            if (index == state.items.length) {
              return _TimelineFooter(
                isLoading: state.isLoadingMore,
                errorMessage: state.errorMessage,
                hasMore: state.hasMore,
                onRetry: cubit.loadMore,
              );
            }
            final activity = state.items[index];
            final showDate =
                index == 0 ||
                !_sameDate(
                  activity.createdAt,
                  state.items[index - 1].createdAt,
                );
            return _ActivityContent(
              activity: activity,
              actorName: _actorName(activity),
              currency: widget.room.currency,
              showDate: showDate,
            );
          },
          indicatorBuilder: (_, index) => index >= state.items.length
              ? Indicator.transparent()
              : Indicator.dot(size: 12, color: _eventColor(state.items[index])),
          startConnectorBuilder: (_, index) => index == 0
              ? const TransparentConnector()
              : const SolidLineConnector(
                  color: AppColors.border,
                  thickness: 1.4,
                ),
          endConnectorBuilder: (_, index) => index >= state.items.length - 1
              ? const TransparentConnector()
              : const SolidLineConnector(
                  color: AppColors.border,
                  thickness: 1.4,
                ),
          nodePositionBuilder: (_, _) => 0.06,
        ),
      ),
    );
  }

  String _actorName(RoomActivity activity) {
    // Member events identify the affected member, while expense events are
    // attributed to the actor. Metadata remains a fallback for old logs.
    if (activity.isMember && activity.memberUserId != null) {
      return _names[activity.memberUserId!] ??
          activity.memberDisplayName ??
          _names[activity.actorUserId] ??
          'Member';
    }
    return _names[activity.actorUserId] ?? 'Member';
  }

  Color _eventColor(RoomActivity activity) {
    if (activity.isMember) return AppColors.secondary;
    if (activity.isExpense) return AppColors.primary;
    return AppColors.muted;
  }

  bool _sameDate(DateTime? first, DateTime? second) {
    if (first == null || second == null) return first == second;
    final firstLocal = first.toLocal();
    final secondLocal = second.toLocal();
    return firstLocal.year == secondLocal.year &&
        firstLocal.month == secondLocal.month &&
        firstLocal.day == secondLocal.day;
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final RoomActivityFilter selected;
  final ValueChanged<RoomActivityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        scrollDirection: Axis.horizontal,
        children: [
          for (final filter in RoomActivityFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_label(filter)),
                selected: selected == filter,
                showCheckmark: false,
                onSelected: (_) => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }

  String _label(RoomActivityFilter filter) => switch (filter) {
    RoomActivityFilter.all => 'All',
    RoomActivityFilter.expenses => 'Expenses',
    RoomActivityFilter.members => 'Members',
  };
}

class _ActivityContent extends StatelessWidget {
  const _ActivityContent({
    required this.activity,
    required this.actorName,
    required this.currency,
    required this.showDate,
  });

  final RoomActivity activity;
  final String actorName;
  final String? currency;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final details = _details();
    return Padding(
      padding: EdgeInsets.only(left: 14, right: 2, bottom: showDate ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDate) ...[
            Text(
              _dateLabel(activity.createdAt),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      MemberAvatar(name: actorName, size: 58),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 3,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _icon(),
                            color: AppColors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$actorName ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: details.action),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (details.subject != null) ...[
                        const SizedBox(height: 8),
                        StatusPill(
                          label: details.subject!,
                          color: AppColors.paleBlue,
                          textColor: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (details.amount != null)
                      Text(
                        details.amount!,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _time(activity.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ActivityDetails _details() {
    final amountText = _amountText();
    return switch (activity.type) {
      'room_created' => const _ActivityDetails('created the room'),
      'expense_created' => _ActivityDetails(
        'added an expense',
        subject: activity.expenseTitle,
        amount: amountText,
      ),
      'expense_updated' => _ActivityDetails(
        'updated an expense',
        subject: activity.expenseTitle,
        amount: amountText,
      ),
      'expense_deleted' => _ActivityDetails(
        'deleted an expense',
        subject: activity.expenseTitle,
        amount: amountText,
      ),
      'member_joined' => _ActivityDetails(
        'joined the room',
        subject: activity.memberDisplayName,
      ),
      'member_left' || 'member_removed' => _ActivityDetails(
        'removed a member',
        subject: activity.memberDisplayName,
      ),
      _ => const _ActivityDetails('changed the room'),
    };
  }

  String? _amountText() {
    final amount = activity.amountInCents;
    if (activity.type == 'expense_updated') {
      final previousAmount = activity.previousAmountInCents;
      final newAmount = activity.newAmountInCents;
      if (previousAmount != null && newAmount != null) {
        return '${formatCurrency(previousAmount, currency: currency)} -> '
            '${formatCurrency(newAmount, currency: currency)}';
      }
    }
    return amount == null ? null : formatCurrency(amount, currency: currency);
  }

  IconData _icon() {
    if (activity.isMember) return Icons.person_add_alt_1_rounded;
    if (activity.isExpense) return Icons.receipt_long_rounded;
    return Icons.home_work_outlined;
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Recent';
    final local = value.toLocal();
    final today = DateTime.now();
    final date = DateTime(local.year, local.month, local.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    if (date == todayDate) return 'Today';
    if (date == todayDate.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${local.day}/${local.month}/${local.year}';
  }

  String _time(DateTime? value) {
    if (value == null) return 'Just now';
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _ActivityDetails {
  const _ActivityDetails(this.action, {this.subject, this.amount});

  final String action;
  final String? subject;
  final String? amount;
}

class _TimelineFooter extends StatelessWidget {
  const _TimelineFooter({
    required this.isLoading,
    required this.errorMessage,
    required this.hasMore,
    required this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (errorMessage != null) {
      return _ErrorView(message: errorMessage!, onRetry: onRetry);
    }
    return hasMore ? const SizedBox(height: 20) : const SizedBox.shrink();
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
