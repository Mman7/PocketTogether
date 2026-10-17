import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/features/profile/models/user.dart';
import 'package:pocket_together/features/rooms/data/room_repository.dart';
import 'package:pocket_together/features/rooms/models/room.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('uses the saved profile name in the rooms greeting', (
    tester,
  ) async {
    final harness = TestAppHarness(signedIn: true);
    harness.profileRepository.profiles['test-user'] = const UserProfile(
      uid: 'test-user',
      displayName: 'Jamie Together',
      email: 'jamie@example.com',
    );

    await pumpTestApp(tester, harness);

    expect(find.text('Good evening, Jamie Together 👋'), findsOneWidget);
  });

  testWidgets('launches into rooms and switches main sections', (tester) async {
    final harness = TestAppHarness(signedIn: true);
    harness.roomRepository.rooms.addAll([
      const Room(
        id: 'japan-room',
        name: 'Japan Trip',
        description: 'Tokyo & Kyoto Autumn',
        currency: 'JPY',
        ownerId: 'test-user',
      ),
      const Room(
        id: 'home-room',
        name: 'Monthly Household',
        description: 'Rent, groceries & utilities',
        currency: 'MYR',
        ownerId: 'test-user',
      ),
      const Room(
        id: 'other-user-room',
        name: 'Private room',
        currency: 'MYR',
        ownerId: 'another-user',
      ),
    ]);
    await pumpTestApp(tester, harness);

    expect(find.text('Your rooms'), findsOneWidget);
    expect(find.text('Japan Trip'), findsOneWidget);
    expect(find.text('Private room'), findsNothing);
    expect(harness.roomRepository.requestedOwners, contains('test-user'));
    await tester.scrollUntilVisible(
      find.text('Monthly Household'),
      280,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('rooms-home')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Monthly Household'), findsOneWidget);

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Spending by member'),
      260,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('statistics-page')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Spending by member'), findsOneWidget);
  });

  testWidgets('create room requires a name and shows invite codes', (
    tester,
  ) async {
    final harness = TestAppHarness(signedIn: true);
    final completion = Completer<Room>();
    harness.roomRepository.pendingCreate = completion;
    await pumpTestApp(tester, harness);

    await tester.tap(find.text('Create room'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create room').last);
    await tester.pumpAndSettle();
    expect(find.text('Give your room a name'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Weekend in Penang',
    );
    await tester.tap(find.text('Create room').last);
    await tester.pump();
    expect(find.text('Creating room…'), findsOneWidget);
    expect(find.text('Your room is ready'), findsNothing);

    completion.complete(
      const Room(
        id: 'generated-room-id',
        name: 'Weekend in Penang',
        currency: 'MYR',
        ownerId: 'test-user',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your room is ready'), findsOneWidget);
    expect(find.text('generated-room-id'), findsOneWidget);
    expect(find.text('FLOW-72MX'), findsOneWidget);
    expect(harness.roomRepository.requestedName, 'Weekend in Penang');
    expect(harness.roomRepository.requestedCurrency, 'MYR');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Weekend in Penang'), findsOneWidget);
  });

  testWidgets('create room shows repository errors without losing input', (
    tester,
  ) async {
    final harness = TestAppHarness(signedIn: true);
    harness.roomRepository.failure = const RoomFailure(
      'Unable to create room. Please try again.',
    );
    await pumpTestApp(tester, harness);

    await tester.tap(find.text('Create room'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Weekend in Penang',
    );
    await tester.tap(find.text('Create room').last);
    await tester.pumpAndSettle();

    expect(find.text('Create a room'), findsOneWidget);
    expect(
      find.text('Unable to create room. Please try again.'),
      findsOneWidget,
    );
    expect(
      (tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller)
          ?.text,
      'Weekend in Penang',
    );
  });

  testWidgets('join room exposes invalid and expired invite feedback', (
    tester,
  ) async {
    await pumpTestApp(tester, TestAppHarness(signedIn: true));

    await tester.tap(find.text('Join room'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'BAD123');
    await tester.enterText(find.byType(TextFormField).at(1), 'TOKYO24');
    await tester.tap(find.text('Join room').last);
    await tester.pumpAndSettle();
    expect(
      find.text('We couldn’t find that room code. Check it and try again.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'JP4K8D');
    await tester.enterText(find.byType(TextFormField).at(1), 'EXPIRED');
    await tester.tap(find.text('Join room').last);
    await tester.pumpAndSettle();
    expect(
      find.text('This invite has expired. Ask for a new one.'),
      findsOneWidget,
    );
  });

  testWidgets('rooms home fits a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpTestApp(tester, TestAppHarness(signedIn: true));

    expect(find.text('Create room'), findsOneWidget);
    expect(find.text('Join room'), findsOneWidget);
    expect(find.text('No rooms yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
