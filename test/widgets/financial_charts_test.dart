import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/services/transaction_service.dart';
import 'package:pueblo_bank/widgets/category_distribution_chart.dart';
import 'package:pueblo_bank/widgets/financial_evolution_chart.dart';

class _ChartService extends TransactionService {
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
          date: DateTime(2026, 9, 13),
        ),
      ],
      cursor: null,
    );
  }
}

void main() {
  testWidgets('exibe estados vazios para os graficos sem transacoes',
      (tester) async {
    final provider = TransactionProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                CategoryDistributionChart(provider: provider),
                FinancialEvolutionChart(provider: provider),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ainda não há dados para exibir.'), findsNWidgets(2));
  });

  testWidgets('descreve os graficos financeiros para tecnologias assistivas',
      (tester) async {
    final provider = TransactionProvider(service: _ChartService());
    provider.setUser('user-1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                CategoryDistributionChart(provider: provider),
                FinancialEvolutionChart(provider: provider),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Distribuição financeira'), findsOneWidget);
    expect(find.bySemanticsLabel('Evolução financeira'), findsOneWidget);
  });
}
