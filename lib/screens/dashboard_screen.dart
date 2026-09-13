import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../routes.dart';
import '../widgets/category_distribution_chart.dart';
import '../widgets/financial_evolution_chart.dart';
import '../widgets/financial_summary.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final auth = context.read<AuthProvider>();
    final recentItems = provider.summaryItems.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão geral'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.login,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadFirstPage,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Olá, ${auth.user?.email?.split('@').first ?? 'pessoa'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text('Acompanhe o movimento da sua conta.'),
            const SizedBox(height: 24),
            FinancialSummary(provider: provider),
            const SizedBox(height: 24),
            Text('Distribuição', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            CategoryDistributionChart(provider: provider),
            const SizedBox(height: 24),
            Text('Evolução financeira', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FinancialEvolutionChart(provider: provider),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.transactionForm),
              icon: const Icon(Icons.add),
              label: const Text('Nova transação'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.transactions),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Ver transações'),
            ),
            if (recentItems.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Recentes', style: Theme.of(context).textTheme.titleMedium),
              for (final item in recentItems)
                ListTile(
                  leading: Icon(
                    item.category == TransactionCategory.deposit
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                  title: Text(
                    item.description.isEmpty
                        ? (item.isDeposit ? 'Depósito' : 'Saque')
                        : item.description,
                  ),
                  trailing: Text('R\$ ${item.amount.toStringAsFixed(2)}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
