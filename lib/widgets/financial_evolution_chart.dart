import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_typography.dart';
import '../providers/transaction_provider.dart';
import '../utils/brl_currency.dart';
import 'app_feedback.dart';
import 'loading_placeholder.dart';

String _formatCompactBrl(double value) {
  final absoluteValue = value.abs();
  if (absoluteValue >= 1000000) {
    return r'R$ ' '${_formatCompactNumber(value / 1000000)} mi';
  }
  if (absoluteValue >= 1000) {
    return r'R$ ' '${_formatCompactNumber(value / 1000)} mil';
  }
  return r'R$ ' + value.round().toString();
}

String _formatCompactNumber(double value) {
  final formatted = value.toStringAsFixed(1).replaceFirst('.', ',');
  return formatted.endsWith(',0')
      ? formatted.substring(0, formatted.length - 2)
      : formatted;
}

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
    final values = spots.map((spot) => spot.y);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final valueRange = maxValue - minValue;
    final padding = valueRange == 0
        ? (maxValue.abs() * 0.2).clamp(100.0, double.infinity)
        : valueRange * 0.15;
    final minY = minValue - padding;
    final maxY = maxValue + padding;
    final yInterval = (maxY - minY) / 4;
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
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.colorScheme.outlineVariant.withAlpha(90),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 72,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(
                          _formatCompactBrl(value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
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
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipMargin: 8,
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
