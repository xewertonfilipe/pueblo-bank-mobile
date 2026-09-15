import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import '../providers/transaction_provider.dart';
import 'loading_placeholder.dart';

final _brlFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class FinancialSummary extends StatelessWidget {
  const FinancialSummary({required this.provider, super.key});

  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = provider.summaryLoading;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo atual', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            isLoading
                ? const LoadingPlaceholder(width: 140, height: 28)
                : Text(
                    _brlFormat.format(provider.summaryBalance),
                    style: AppTypography.financialPrimary(theme.textTheme),
                  ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryItem(
                  label: 'Depósitos',
                  value: provider.summaryDeposits,
                  format: _brlFormat,
                  color: AppColors.income,
                  isLoading: isLoading,
                ),
                _SummaryItem(
                  label: 'Saques',
                  value: provider.summaryWithdrawals,
                  format: _brlFormat,
                  color: AppColors.expense,
                  isLoading: isLoading,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.format,
    required this.color,
    required this.isLoading,
  });

  final String label;
  final double value;
  final NumberFormat format;
  final Color color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: LoadingPlaceholder(width: 80, height: 16),
          )
        else
          Text(
            format.format(value),
            style: AppTypography.financialCompact(
              theme.textTheme,
              color: color,
            ),
          ),
      ],
    );
  }
}
