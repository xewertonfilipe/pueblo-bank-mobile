import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/screens/transaction_form_screen.dart';

void main() {
  Widget buildApp() {
    return const MaterialApp(
      home: TransactionFormScreen(),
    );
  }

  Future<void> pumpEditForm(
    WidgetTester tester, {
    DateTime? date,
  }) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    await tester.pump();
    final transaction = TransactionModel(
      id: 'transaction-1',
      amount: 100,
      category: TransactionCategory.deposit,
      date: date ?? DateTime(2026, 9, 14, 18),
      description: 'Compra',
    );
    Navigator.of(tester.element(find.byType(Scaffold))).push(
      MaterialPageRoute(
        settings: RouteSettings(
          arguments: TransactionFormArguments(
            source: TransactionFormSource.transactions,
            transaction: transaction,
          ),
        ),
        builder: (_) => const TransactionFormScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton editButton(WidgetTester tester) {
    return tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
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

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Informe um valor positivo.'), findsOneWidget);
  });

  testWidgets('identifica o controle de seleção de data', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.byTooltip('Selecionar data'), findsOneWidget);
  });

  testWidgets('desabilita salvar ao abrir edicao sem alteracoes', (tester) async {
    await pumpEditForm(tester);

    expect(editButton(tester).onPressed, isNull);
  });

  testWidgets('habilita e desabilita salvar ao alterar e reverter o valor',
      (tester) async {
    await pumpEditForm(tester);
    final amountField = find.byType(TextFormField).first;

    await tester.enterText(amountField, '200');
    await tester.pump();
    expect(editButton(tester).onPressed, isNotNull);

    await tester.enterText(amountField, '100');
    await tester.pump();
    expect(editButton(tester).onPressed, isNull);
  });

  testWidgets('detecta alteracoes de descricao e categoria', (tester) async {
    await pumpEditForm(tester);
    final descriptionField = find.byType(TextFormField).last;

    await tester.enterText(descriptionField, 'Outra compra');
    await tester.pump();
    expect(editButton(tester).onPressed, isNotNull);

    await tester.enterText(descriptionField, 'Compra');
    await tester.pump();
    expect(editButton(tester).onPressed, isNull);

    await tester.tap(find.text('Saque'));
    await tester.pump();
    expect(editButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Depósito'));
    await tester.pump();
    expect(editButton(tester).onPressed, isNull);
  });

  testWidgets('mantem salvar habilitado para nova transacao', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('Nenhum comprovante anexado.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(
        FilledButton,
        'Salvar depósito',
      )).onPressed,
      isNotNull,
    );
  });

  testWidgets('abre edição com comprovante inválido sem falhar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    await tester.pump();
    final transaction = TransactionModel(
      id: 'transaction-with-receipt',
      amount: 100,
      category: TransactionCategory.deposit,
      date: DateTime(2026, 9, 14),
      receiptUrl: 'gs://invalid-receipt-path',
    );
    Navigator.of(tester.element(find.byType(Scaffold))).push(
      MaterialPageRoute(
        settings: RouteSettings(
          arguments: TransactionFormArguments(
            source: TransactionFormSource.transactions,
            transaction: transaction,
          ),
        ),
        builder: (_) => const TransactionFormScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Comprovante anexado, mas não foi possível carregá-lo.'),
      findsOneWidget,
    );
  });
}
