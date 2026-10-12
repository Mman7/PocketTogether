import 'dart:async';

import 'package:pocket_together/app/app.dart';
import 'package:pocket_together/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('signed-out users can navigate between auth screens', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(PocketTogetherApp(authRepository: repository));
    await tester.pumpAndSettle();

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
    final repository = _FakeAuthRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(PocketTogetherApp(authRepository: repository));
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
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

  testWidgets('registration enforces password rules and creates an account', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(PocketTogetherApp(authRepository: repository));
    await tester.pumpAndSettle();
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
    expect(repository.registeredName, 'Alex Morgan');
    expect(find.text('Your rooms'), findsOneWidget);
  });

  testWidgets('password reset submits without exposing account existence', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(PocketTogetherApp(authRepository: repository));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'alex@example.com',
    );
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(repository.resetEmail, 'alex@example.com');
    expect(
      find.text(
        'If there is an account for that email, a reset link is on its way.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('launches into rooms and switches main sections', (tester) async {
    await tester.pumpWidget(_signedInApp());
    await tester.pumpAndSettle();

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

  testWidgets('room dashboard opens the category sheet from add expense', (
    tester,
  ) async {
    await tester.pumpWidget(_signedInApp());
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(_signedInApp());
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('4 members'));
    await tester.pumpAndSettle();
    expect(find.text('Just me'), findsOneWidget);
    await tester.tap(find.text('Just me'));
    await tester.pumpAndSettle();
    expect(find.text('Just me'), findsOneWidget);
  });

  testWidgets('create room requires a name and shows copyable invite codes', (
    tester,
  ) async {
    await tester.pumpWidget(_signedInApp());
    await tester.pumpAndSettle();

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

  testWidgets('join room exposes invalid room and expired invite feedback', (
    tester,
  ) async {
    await tester.pumpWidget(_signedInApp());
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(_signedInApp());
    await tester.pumpAndSettle();

    expect(find.text('Create room'), findsOneWidget);
    expect(find.text('Join room'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

PocketTogetherApp _signedInApp() {
  final repository = _FakeAuthRepository(signedIn: true);
  addTearDown(repository.dispose);
  return PocketTogetherApp(authRepository: repository);
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this._signedIn = false});

  final StreamController<bool> _authState = StreamController<bool>.broadcast(
    sync: true,
  );
  bool _signedIn;
  String? registeredName;
  String? resetEmail;

  @override
  bool get isSignedIn => _signedIn;

  @override
  Stream<bool> get authStateChanges => _authState.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _signedIn = true;
    _authState.add(true);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registeredName = name;
    _signedIn = true;
    _authState.add(true);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetEmail = email;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _authState.add(false);
  }

  Future<void> dispose() => _authState.close();
}
