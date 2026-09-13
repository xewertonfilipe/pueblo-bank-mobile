import 'package:flutter/material.dart';

import '../providers/transaction_provider.dart';

class FinancialSummary extends StatelessWidget {
  const FinancialSummary({required this.provider, super.key});

  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saldo atual'),
            const SizedBox(height: 6),
            Text(
              'R\$ ${provider.summaryBalance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryItem(
                  label: 'Depósitos',
                  value: provider.summaryDeposits,
                  color: Colors.green,
                ),
                _SummaryItem(
                  label: 'Saques',
                  value: provider.summaryWithdrawals,
                  color: Colors.red,
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
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
