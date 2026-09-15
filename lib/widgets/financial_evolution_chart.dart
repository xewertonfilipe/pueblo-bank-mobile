import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_typography.dart';
import '../providers/transaction_provider.dart';
import '../utils/brl_currency.dart';
import 'app_feedback.dart';
import 'loading_placeholder.dart';

class FinancialEvolutionChart extends StatelessWidget {
  const FinancialEvolutionChart({required this.provider, super.key});
  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.summaryLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            height: 190,
            child: Center(child: LoadingPlaceholder(width: 220, height: 4)),
          ),
        ),
      );
    }
    final ordered = [...provider.summaryItems]
      ..sort((a, b) => a.date.compareTo(b.date));
    var balance = 0.0;
    final spots = <FlSpot>[];
    for (var index = 0; index < ordered.length; index++) {
      balance += ordered[index].isDeposit
          ? ordered[index].amount
          : -ordered[index].amount;
      spots.add(FlSpot(index.toDouble(), balance));
    }
    if (spots.isEmpty) {
      return Card(
        child: SizedBox(
          height: 220,
          child: AppFeedbackPanel(
            icon: Icons.show_chart,
            title: 'Ainda não há dados para exibir.',
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final tooltipStyle = AppTypography.financialValue(
      theme.textTheme.bodySmall,
      color: Colors.white,
    );
    return Semantics(
      container: true,
      label: 'Evolução financeira',
      value:
          'Saldo acumulado em ${spots.length} transações. Saldo final: R\$ ${formatBrlCurrency(balance)}.',
      hint: 'Gráfico de evolução financeira',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF075985),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map(
                          (spot) => LineTooltipItem(
                            'R\$ ${formatBrlCurrency(spot.y)}',
                            tooltipStyle,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
