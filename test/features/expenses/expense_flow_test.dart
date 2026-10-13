import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('room dashboard opens category sheet from add expense', (
    tester,
  ) async {
    await pumpTestApp(tester, TestAppHarness(signedIn: true));

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
    await pumpTestApp(tester, TestAppHarness(signedIn: true));

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
}
