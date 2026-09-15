import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/services/transaction_service.dart';
import 'package:pueblo_bank/widgets/financial_summary.dart';

class _SummaryService extends TransactionService {
  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 20,
  }) async {
    return TransactionPage(
      items: [
        TransactionModel(
          id: 'deposit-1',
          amount: 1234.56,
          category: TransactionCategory.deposit,
          date: DateTime(2026, 9, 14),
        ),
        TransactionModel(
          id: 'withdrawal-1',
          amount: 234.56,
          category: TransactionCategory.withdrawal,
          date: DateTime(2026, 9, 14),
        ),
      ],
      cursor: null,
    );
  }
}

void main() {
  testWidgets('exibe os valores do resumo no formato decimal brasileiro', (
    tester,
  ) async {
    final provider = TransactionProvider(service: _SummaryService());
    provider.setUser('user-1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinancialSummary(provider: provider),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder currencyText(String amount) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data?.replaceAll('\u00a0', ' ') == 'R\$ $amount',
      );
    }

    expect(currencyText('1.000,00'), findsOneWidget);
    expect(currencyText('1.234,56'), findsOneWidget);
    expect(currencyText('234,56'), findsOneWidget);
    expect(find.textContaining('1000.00'), findsNothing);
  });
}
