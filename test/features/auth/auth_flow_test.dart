import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('signed-out users can navigate between auth screens', (
    tester,
  ) async {
    final harness = TestAppHarness();
    await pumpTestApp(tester, harness);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('PocketTogether'), findsOneWidget);
    expect(
      find.text('This preview does not sign in to an account.'),
      findsNothing,
    );
    expect(find.text('Ledger Ready'), findsNothing);

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('login validates fields and routes after sign-in', (
    tester,
  ) async {
    final harness = TestAppHarness();
    await pumpTestApp(tester, harness);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'alex@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'Password1',
    );
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Your rooms'), findsOneWidget);
  });

  testWidgets('Google sign-in routes to rooms', (tester) async {
    final harness = TestAppHarness();
    await pumpTestApp(tester, harness);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(harness.authRepository.googleSignInRequested, isTrue);
    expect(find.text('Your rooms'), findsOneWidget);
  });

  testWidgets('registration enforces password rules and creates a profile', (
    tester,
  ) async {
    final harness = TestAppHarness();
    await pumpTestApp(tester, harness);
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create account').first);
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('auth-name')),
      'Alex Morgan',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'alex@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'Password1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm-password')),
      'Password1',
    );
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();

    expect(harness.authRepository.registeredName, 'Alex Morgan');
    expect(
      harness.profileRepository.profiles['test-user']?.displayName,
      'Alex Morgan',
    );
    expect(
      harness.profileRepository.profiles['test-user']?.email,
      'alex@example.com',
    );
    expect(find.text('Your rooms'), findsOneWidget);
  });

  testWidgets('password reset does not expose account existence', (
    tester,
  ) async {
    final harness = TestAppHarness();
    await pumpTestApp(tester, harness);
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'alex@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(harness.authRepository.resetEmail, 'alex@example.com');
    expect(
      find.text(
        'If there is an account for that email, a reset link is on its way.',
      ),
      findsOneWidget,
    );
  });
}
