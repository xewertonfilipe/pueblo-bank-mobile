import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/screens/transactions_screen.dart';
import 'package:pueblo_bank/services/transaction_service.dart';

class _FakeTransactionService extends TransactionService {
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

    expect(deposit.style?.color, Colors.green);
    expect(withdrawal.style?.color, Colors.red);
    expect(find.text('Entrada'), findsOneWidget);
    expect(find.text('Saída'), findsOneWidget);
  });
}
