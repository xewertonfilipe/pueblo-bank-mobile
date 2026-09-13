import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/transaction_provider.dart';

class CategoryDistributionChart extends StatelessWidget {
  const CategoryDistributionChart({required this.provider, super.key});
  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    final total = provider.summaryDeposits + provider.summaryWithdrawals;
    if (total == 0) return const Card(child: SizedBox(height: 180, child: Center(child: Text('Ainda não há dados para exibir.'))));
    return SizedBox(
      height: 220,
      child: Card(
        child: PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 38, sections: [
          PieChartSectionData(value: provider.summaryDeposits, color: Colors.green, title: 'Depósitos', radius: 72, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
          PieChartSectionData(value: provider.summaryWithdrawals, color: Colors.red, title: 'Saques', radius: 72, titleStyle: const TextStyle(color: Colors.white, fontSize: 12)),
        ])),
      ),
    );
  }
}
