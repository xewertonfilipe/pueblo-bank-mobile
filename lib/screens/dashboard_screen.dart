import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import '../main.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../routes.dart';
import '../utils/brl_currency.dart';
import '../widgets/category_distribution_chart.dart';
import '../widgets/financial_evolution_chart.dart';
import '../widgets/financial_summary.dart';
import '../widgets/loading_placeholder.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  final _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final shouldShow = _scrollController.offset > 300;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didPopNext() {
    final provider = context.read<TransactionProvider>();
    if (provider.shouldScrollToTop) {
      provider.clearScrollFlag();
      _scrollToTop().then((_) => provider.refreshSummaryIfNeeded());
    } else {
      provider.refreshSummaryIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final recentItems = provider.summaryItems.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão geral'),
        actions: [
          if (auth.biometricEnabled)
            IconButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Desativar biometria'),
                    content: const Text(
                        'Você precisará digitar sua senha para entrar da próxima vez. Deseja continuar?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Desativar')),
                    ],
                  ),
                );
                if (confirmed != true) return;
                await auth.disableBiometric();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, Routes.login, (route) => false);
                }
              },
              icon: const Icon(Icons.fingerprint),
              tooltip: 'Desativar biometria',
            ),
          IconButton(
            onPressed: () async {
              if (auth.biometricEnabled) {
                await auth.lock();
              } else {
                await auth.signOut();
              }
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
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Olá, ${auth.user?.email?.split('@').first ?? 'pessoa'}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Acompanhe o movimento da sua conta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FinancialSummary(provider: provider),
            const SizedBox(height: 24),
            Text('Distribuição', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            CategoryDistributionChart(provider: provider),
            const SizedBox(height: 24),
            Text('Evolução financeira', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FinancialEvolutionChart(provider: provider),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.transactionForm),
              icon: const Icon(Icons.add),
              label: const Text('Nova transação'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.transactions),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Ver transações'),
            ),
            if (provider.summaryLoading) ...[
              const SizedBox(height: 28),
              Text('Recentes', style: theme.textTheme.titleMedium),
              for (var i = 0; i < 3; i++)
                const ListTile(
                  leading: LoadingPlaceholder(
                      width: 24,
                      height: 24,
                      borderRadius: BorderRadius.all(Radius.circular(12))),
                  title: LoadingPlaceholder(width: 140, height: 14),
                  trailing: LoadingPlaceholder(width: 60, height: 14),
                ),
            ] else if (recentItems.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Recentes', style: theme.textTheme.titleMedium),
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
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    'R\$ ${formatBrlCurrency(item.amount)}',
                    style: AppTypography.financialCompact(
                      theme.textTheme,
                      color:
                          item.isDeposit ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.transactionForm,
                    arguments: item,
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              tooltip: 'Voltar ao topo',
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}
