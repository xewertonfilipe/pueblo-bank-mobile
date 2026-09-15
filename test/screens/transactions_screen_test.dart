import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pueblo_bank/app_colors.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/screens/transactions_screen.dart';
import 'package:pueblo_bank/services/transaction_service.dart';

class _FakeTransactionService extends TransactionService {
  @override
  Future<void> delete(String userId, String transactionId) async {}

  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 10,
  }) async {
    return TransactionPage(
      items: [
        TransactionModel(
          id: 'deposit-1',
          amount: 1234.56,
          category: TransactionCategory.deposit,
          date: DateTime(2026, 9, 14),
          description: 'Entrada',
        ),
        TransactionModel(
          id: 'withdrawal-1',
          amount: 234.56,
          category: TransactionCategory.withdrawal,
          date: DateTime(2026, 9, 13),
          description: 'Saída',
        ),
      ],
      cursor: null,
    );
  }
}

class _EmptyTransactionService extends TransactionService {
  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 10,
  }) async {
    return const TransactionPage(items: [], cursor: null);
  }
}

void main() {
  testWidgets('exibe transações no formato brasileiro e com cores', (
    tester,
  ) async {
    final provider = TransactionProvider(service: _FakeTransactionService());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );
    provider.setUser('user-1');
    await tester.pumpAndSettle();

    final deposit = tester.widget<Text>(find.text('R\$ 1.234,56'));
    final withdrawal = tester.widget<Text>(find.text('R\$ 234,56'));

    expect(deposit.style?.color, AppColors.income);
    expect(withdrawal.style?.color, AppColors.expense);
    expect(find.text('Entrada'), findsOneWidget);
    expect(find.text('Saída'), findsOneWidget);
  });

  testWidgets('expõe valor e tipo da transação para tecnologias assistivas',
      (tester) async {
    final provider = TransactionProvider(service: _FakeTransactionService());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );
    provider.setUser('user-1');
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('Depósito')), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp(r'Valor R\$ 1\.234,56')),
      findsWidgets,
    );
  });

  testWidgets('mantém a lista utilizável em tela estreita com texto ampliado',
      (tester) async {
    final provider = TransactionProvider(service: _FakeTransactionService());
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: TransactionsScreen()),
        ),
      ),
    );
    provider.setUser('user-1');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('permite selecionar e limpar o filtro de categoria', (
    tester,
  ) async {
    final provider = TransactionProvider(service: _FakeTransactionService());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );
    provider.setUser('user-1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Depósitos'));
    await tester.pumpAndSettle();

    expect(provider.category, TransactionCategory.deposit);
    expect(find.text('Filtros: Depósitos'), findsOneWidget);
    expect(find.text('Limpar filtros'), findsOneWidget);

    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();

    expect(provider.category, isNull);
    expect(find.text('Filtros: Todas as transações'), findsOneWidget);
  });

  testWidgets('oferece limpar filtros quando não há resultados',
      (tester) async {
    final provider = TransactionProvider(service: _EmptyTransactionService());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );
    provider.setUser('user-1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Depósitos'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma transação encontrada para estes filtros.'),
      findsOneWidget,
    );
    expect(find.text('Limpar filtros'), findsNWidgets(2));
  });

  testWidgets('confirma exclusão antes de remover uma transação',
      (tester) async {
    final provider = TransactionProvider(service: _FakeTransactionService());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );
    provider.setUser('user-1');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ações').first);
    await tester.pumpAndSettle();
    expect(find.text('Excluir'), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pump();
    expect(find.text('Excluir transação?'), findsOneWidget);
    expect(find.text('Essa ação remove o registro financeiro permanentemente.'),
        findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(provider.items, hasLength(1));
    expect(find.text('Transação excluída.'), findsOneWidget);
  });
}
