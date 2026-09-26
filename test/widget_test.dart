import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CashOrg app test placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('CashOrg'),
        ),
      ),
    );
    expect(find.text('CashOrg'), findsOneWidget);
  });
}
