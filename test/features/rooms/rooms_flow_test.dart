import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/features/profile/models/user.dart';

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
    await pumpTestApp(tester, TestAppHarness(signedIn: true));

    expect(find.text('Your rooms'), findsOneWidget);
    expect(find.text('Japan Trip'), findsOneWidget);
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
    await pumpTestApp(tester, TestAppHarness(signedIn: true));

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
    await tester.pumpAndSettle();
    expect(find.text('Your room is ready'), findsOneWidget);
    expect(find.text('FAM8-K2Q'), findsOneWidget);
    expect(find.text('FLOW-72MX'), findsOneWidget);
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
    expect(tester.takeException(), isNull);
  });
}
