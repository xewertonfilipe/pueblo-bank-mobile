import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../providers/transaction_provider.dart';
import 'app_feedback.dart';
import 'loading_placeholder.dart';

class CategoryDistributionChart extends StatelessWidget {
  const CategoryDistributionChart({required this.provider, super.key});
  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.summaryLoading) {
      return const SizedBox(
        height: 220,
        child: Card(
          child: Center(
              child: LoadingPlaceholder(
                  width: 120,
                  height: 120,
                  borderRadius: BorderRadius.all(Radius.circular(60)))),
        ),
      );
    }
    final total = provider.summaryDeposits + provider.summaryWithdrawals;
    if (total == 0) {
      return Card(
        child: SizedBox(
          height: 180,
          child: AppFeedbackPanel(
            icon: Icons.pie_chart_outline,
            title: 'Ainda não há dados para exibir.',
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final chartLabelStyle = theme.textTheme.labelSmall?.copyWith(
      color: Colors.white,
    );
    return SizedBox(
      height: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PieChart(
              PieChartData(sectionsSpace: 3, centerSpaceRadius: 30, sections: [
            PieChartSectionData(
                value: provider.summaryDeposits,
                color: AppColors.income,
                title: 'Depósitos',
                radius: 60,
                titleStyle: chartLabelStyle),
            PieChartSectionData(
                value: provider.summaryWithdrawals,
                color: AppColors.expense,
                title: 'Saques',
                radius: 60,
                titleStyle: chartLabelStyle),
          ])),
        ),
      ),
    );
  }
}
