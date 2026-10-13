import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_together/features/profile/model/user.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('shows the Firestore profile and signs out', (tester) async {
    final harness = TestAppHarness(signedIn: true);
    harness.profileRepository.profiles['test-user'] = const UserProfile(
      uid: 'test-user',
      displayName: 'Alex Profile',
      email: 'profile@example.com',
    );
    await pumpTestApp(tester, harness);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    expect(find.text('Alex Profile'), findsOneWidget);
    expect(find.text('profile@example.com'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      240,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('profile-page')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
