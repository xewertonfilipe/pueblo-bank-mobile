import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/widgets/category_distribution_chart.dart';
import 'package:pueblo_bank/widgets/financial_evolution_chart.dart';

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
}
