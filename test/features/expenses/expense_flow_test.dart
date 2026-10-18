import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/features/rooms/models/room_member.dart';
import 'package:pocket_together/features/rooms/models/room_role.dart';
import 'package:pocket_together/features/rooms/models/room.dart';

import '../../support/test_app.dart';

Future<void> _pumpWithJapanRoom(WidgetTester tester) async {
  final harness = await _harnessWithJapanRoom();
  await pumpTestApp(tester, harness);
}

void main() {
  testWidgets('room dashboard opens category sheet from add expense', (
    tester,
  ) async {
    await _pumpWithJapanRoom(tester);

    await tester.tap(find.text('Japan Trip'));
    await tester.pumpAndSettle();
    expect(find.text('Total spent'), findsOneWidget);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('FOOD & DRINKS'), findsOneWidget);
    expect(find.text('TRANSPORT'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Transfer');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer').last);
    await tester.pumpAndSettle();

    expect(find.text('Transfer method'), findsOneWidget);
    expect(find.text('Transfer to'), findsOneWidget);
    expect(find.text('Bank transfer'), findsOneWidget);
    expect(find.text('Split with'), findsNothing);
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Bank transfer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('E-wallet').last);
    await tester.pumpAndSettle();
    expect(find.text('E-wallet'), findsOneWidget);
  });

  testWidgets('expense amount uses phone keypad and split options', (
    tester,
  ) async {
    await _pumpWithJapanRoom(tester);

    await tester.tap(find.text('Japan Trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    final amountField = find.byKey(const ValueKey('expense-amount'));
    expect(amountField, findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(
      tester.widget<TextField>(amountField).keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );

    await tester.tap(amountField);
    await tester.pump();
    expect(tester.testTextInput.isRegistered, isTrue);
    await tester.enterText(amountField, '12x.50');
    expect(tester.widget<TextField>(amountField).controller!.text, isEmpty);
    await tester.enterText(amountField, '12.50');
    expect(tester.widget<TextField>(amountField).controller!.text, '12.50');

    expect(find.text('2 selected'), findsOneWidget);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final secondMember = find.byType(CheckboxListTile).last;
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.ensureVisible(secondMember);
    await tester.tap(secondMember);
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('creates expense with member IDs and exact split cents', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final harness = await _harnessWithJapanRoom();
    await pumpTestApp(tester, harness);

    await tester.tap(find.text('Japan Trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('expense-amount')),
      '10.01',
    );
    await tester.enterText(find.byType(TextField).last, 'Shared lunch');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved =
        harness.expenseRepository.expensesByRoom['japan-room']!.single;
    expect(saved.amountInCents, 1001);
    expect(saved.paidByUserId, 'test-user');
    expect(saved.createdByUserId, 'test-user');
    expect(saved.splitAmountsInCents, {'test-user': 501, 'member-2': 500});
    expect(find.text('Shared lunch'), findsOneWidget);

    await tester.tap(find.text('Shared lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit expense'));
    await tester.pumpAndSettle();
    final noteField = find.byType(TextField).last;
    await tester.enterText(noteField, 'Updated lunch');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Updated lunch'), findsOneWidget);
    expect(
      harness.expenseRepository.expensesByRoom['japan-room']!.single.note,
      'Updated lunch',
    );

    await tester.tap(find.text('Delete expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(harness.expenseRepository.expensesByRoom['japan-room'], isEmpty);
  });
}

Future<TestAppHarness> _harnessWithJapanRoom() async {
  final harness = TestAppHarness(signedIn: true);
  harness.roomRepository.rooms.add(
    const Room(
      id: 'japan-room',
      name: 'Japan Trip',
      description: 'Tokyo & Kyoto Autumn',
      currency: 'JPY',
      ownerId: 'test-user',
    ),
  );
  harness.roomRepository.roomMembers['japan-room'] = const [
    RoomMember(
      userId: 'test-user',
      displayName: 'Alex Morgan',
      role: RoomRole.owner,
    ),
    RoomMember(
      userId: 'member-2',
      displayName: 'Jamie Lee',
      role: RoomRole.member,
    ),
  ];
  return harness;
}
