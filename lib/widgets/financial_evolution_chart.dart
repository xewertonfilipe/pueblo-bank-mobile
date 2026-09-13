import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/transaction_provider.dart';

class FinancialEvolutionChart extends StatelessWidget {
  const FinancialEvolutionChart({required this.provider, super.key});
  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    final ordered = [...provider.summaryItems]..sort((a, b) => a.date.compareTo(b.date));
    var balance = 0.0;
    final spots = <FlSpot>[];
    for (var index = 0; index < ordered.length; index++) {
      balance += ordered[index].isDeposit ? ordered[index].amount : -ordered[index].amount;
      spots.add(FlSpot(index.toDouble(), balance));
    }
    if (spots.isEmpty) return const Card(child: SizedBox(height: 220, child: Center(child: Text('Ainda nao ha dados para exibir.'))));
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(height: 190, child: LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: const Color(0xFF075985), barWidth: 3, dotData: const FlDotData(show: false))])))));
  }
}
