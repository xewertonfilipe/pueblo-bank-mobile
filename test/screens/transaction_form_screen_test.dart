import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/screens/transaction_form_screen.dart';

void main() {
  Widget buildApp() {
    return const MaterialApp(
      home: TransactionFormScreen(),
    );
  }

  testWidgets('formata o valor durante a digitação', (tester) async {
    await tester.pumpWidget(buildApp());

    final amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, '1234,56');

    expect(find.text('1.234,56'), findsOneWidget);
  });

  testWidgets('valida valor vazio', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pump();

    expect(find.text('Informe um valor positivo.'), findsOneWidget);
  });
}
