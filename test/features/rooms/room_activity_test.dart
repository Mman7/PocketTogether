import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/features/rooms/data/room_activity_repository.dart';
import 'package:pocket_together/features/rooms/models/room_activity.dart';
import 'package:pocket_together/features/rooms/presentation/cubit/room_activity_cubit.dart';

void main() {
  test('parses legacy activity fields and safe historical metadata', () {
    final activity = RoomActivity.fromMap('activity-1', {
      'type': 'expense_deleted',
      'actorUserId': 'user-1',
      'expenseId': 'expense-1',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 1, 8, 30)),
      'metadata': {'note': 'Lunch', 'amountInCents': 2500},
    });

    expect(activity.targetType, 'expense');
    expect(activity.targetId, 'expense-1');
    expect(activity.isExpense, isTrue);
    expect(activity.expenseTitle, 'Lunch');
    expect(activity.amountInCents, 2500);
    expect(activity.createdAt, DateTime.utc(2026, 11, 1, 8, 30));
  });

  test('parses a member activity and keeps the member classification', () {
    final activity = RoomActivity.fromMap('activity-2', {
      'type': 'member_joined',
      'targetType': 'member',
      'targetId': 'user-2',
      'actorUserId': 'user-2',
      'metadata': {'displayName': ' Alex '},
    });

    expect(activity.isMember, isTrue);
    expect(activity.isExpense, isFalse);
    expect(activity.memberUserId, 'user-2');
    expect(activity.memberDisplayName, 'Alex');
    expect(activity.createdAt, isNull);
  });

  test('uses the explicit target type when legacy IDs conflict', () {
    final activity = RoomActivity.fromMap('activity-3', {
      'type': 'member_removed',
      'targetType': 'member',
      'expenseId': 'expense-1',
      'memberUserId': 'user-3',
    });

    expect(activity.targetType, 'member');
    expect(activity.targetId, 'user-3');
    expect(activity.isMember, isTrue);
    expect(activity.isExpense, isFalse);
  });

  test('ignores malformed optional fields and metadata entries safely', () {
    final activity = RoomActivity.fromMap('activity-4', {
      'type': 42,
      'actorUserId': <String>['not-a-user-id'],
      'createdAt': 'not-a-date',
      'targetId': 99,
      'metadata': {1: 'ignored', 'expenseTitle': 100},
    });

    expect(activity.type, 'unknown');
    expect(activity.actorUserId, isEmpty);
    expect(activity.targetId, isNull);
    expect(activity.createdAt, isNull);
    expect(activity.metadata, {'expenseTitle': 100});
    expect(activity.expenseTitle, isNull);
  });

  test('accepts integral doubles but rejects fractional metadata amounts', () {
    final integral = RoomActivity(
      id: 'integral',
      type: 'expense_updated',
      actorUserId: 'user-1',
      createdAt: null,
      metadata: const {
        'amountInCents': 2500.0,
        'previousAmountInCents': 2000.5,
      },
    );
    final fractional = RoomActivity(
      id: 'fractional',
      type: 'expense_created',
      actorUserId: 'user-1',
      createdAt: null,
      metadata: const {'amountInCents': 2500.5},
    );

    expect(integral.amountInCents, 2500);
    expect(integral.previousAmountInCents, isNull);
    expect(integral.newAmountInCents, 2500);
    expect(fractional.amountInCents, isNull);
    expect(fractional.newAmountInCents, isNull);
  });

  test('normalizes Timestamp and DateTime while rejecting invalid dates', () {
    final timestampActivity = RoomActivity.fromMap('timestamp', {
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 1, 8, 30)),
    });
    final dateTimeActivity = RoomActivity.fromMap('datetime', {
      'createdAt': DateTime.parse('2026-11-01T08:30:00+02:00'),
    });
    final nullActivity = RoomActivity.fromMap('null', {'createdAt': null});

    expect(timestampActivity.createdAt, DateTime.utc(2026, 11, 1, 8, 30));
    expect(dateTimeActivity.createdAt, DateTime.utc(2026, 11, 1, 6, 30));
    expect(nullActivity.createdAt, isNull);
  });

  test('loads filtered pages and deduplicates pagination results', () async {
    final repository = _FakeActivityRepository(
      pages: {
        RoomActivityFilter.all: [
          _activity('one', DateTime.utc(2026, 11, 1, 10)),
        ],
      },
      nextPage: [
        _activity('one', DateTime.utc(2026, 11, 1, 10)),
        _activity('two', DateTime.utc(2026, 11, 1, 9)),
      ],
    );
    final cubit = RoomActivityCubit(repository);
    addTearDown(cubit.close);

    await cubit.load('room-1');
    expect(cubit.state.items.map((item) => item.id), ['one']);

    await cubit.loadMore();
    expect(cubit.state.items.map((item) => item.id), ['one', 'two']);
    expect(repository.filters, [
      RoomActivityFilter.all,
      RoomActivityFilter.all,
    ]);
  });

  test('stale filter responses cannot replace the selected filter', () async {
    final expenses = Completer<RoomActivityPage>();
    final repository = _FakeActivityRepository(
      pages: {
        RoomActivityFilter.all: [
          _activity('all', DateTime.utc(2026, 11, 1, 10)),
        ],
      },
      delayed: expenses,
    );
    final cubit = RoomActivityCubit(repository);
    addTearDown(cubit.close);

    await cubit.load('room-1');
    final changing = cubit.changeFilter(RoomActivityFilter.expenses);
    await cubit.changeFilter(RoomActivityFilter.members);
    expenses.complete(
      RoomActivityPage(
        items: [_activity('stale', DateTime.utc(2026, 11, 1, 8))],
        hasMore: false,
      ),
    );
    await changing;

    expect(cubit.state.filter, RoomActivityFilter.members);
    expect(cubit.state.items, isEmpty);
  });
}

RoomActivity _activity(String id, DateTime createdAt) => RoomActivity(
  id: id,
  type: 'expense_created',
  actorUserId: 'user-1',
  createdAt: createdAt,
  targetType: 'expense',
  targetId: id,
  metadata: const {'expenseTitle': 'Lunch', 'amountInCents': 2500},
);

class _FakeActivityRepository implements RoomActivityRepository {
  _FakeActivityRepository({
    required this.pages,
    this.nextPage = const [],
    this.delayed,
  });

  final Map<RoomActivityFilter, List<RoomActivity>> pages;
  final List<RoomActivity> nextPage;
  final Completer<RoomActivityPage>? delayed;
  final filters = <RoomActivityFilter>[];
  var _pageCalls = 0;

  @override
  Future<RoomActivityPage> getPage({
    required String roomId,
    RoomActivity? after,
    RoomActivityFilter filter = RoomActivityFilter.all,
    int limit = 20,
  }) async {
    filters.add(filter);
    if (delayed != null && filter == RoomActivityFilter.expenses) {
      return delayed!.future;
    }
    if (after != null) {
      _pageCalls++;
      return RoomActivityPage(items: nextPage, hasMore: false);
    }
    return RoomActivityPage(
      items: pages[filter] ?? const [],
      hasMore: _pageCalls == 0 && filter == RoomActivityFilter.all,
    );
  }
}
