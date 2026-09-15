import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../routes.dart';
import '../utils/brl_currency.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _scrollController = ScrollController();
  double? _dragStartY;
  bool _loadTriggeredThisGesture = false;

  @override
  void initState() {
    super.initState();
    context
        .read<TransactionProvider>()
        .setFilters(startDate: null, endDate: null, category: null);
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final provider = context.read<TransactionProvider>();
      if (_scrollController.position.extentAfter < 500 &&
          provider.hasMore &&
          !provider.loadingMore) {
        provider.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _dragStartY = event.position.dy;
    _loadTriggeredThisGesture = false;
  }

  void _handlePointerMove(
      PointerMoveEvent event, TransactionProvider provider) {
    if (_dragStartY == null || _loadTriggeredThisGesture) {
      return;
    }
    if (!_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent > 0) {
      return;
    }
    final delta = event.position.dy - _dragStartY!;
    if (delta < -30) {
      if (provider.hasMore && !provider.loadingMore) {
        _loadTriggeredThisGesture = true;
        provider.loadNextPage();
      } else if (!provider.hasMore) {
        _loadTriggeredThisGesture = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não há mais transações para carregar.')),
        );
      }
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _dragStartY = null;
    _loadTriggeredThisGesture = false;
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<TransactionProvider>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: provider.startDate == null || provider.endDate == null
          ? null
          : DateTimeRange(start: provider.startDate!, end: provider.endDate!),
    );
    if (range != null) {
      provider.setFilters(
        startDate: range.start,
        endDate: DateTime(
            range.end.year, range.end.month, range.end.day, 23, 59, 59),
        category: provider.category,
      );
    }
  }

  void _setCategory(TransactionCategory? category) {
    final provider = context.read<TransactionProvider>();
    provider.setFilters(
      startDate: provider.startDate,
      endDate: provider.endDate,
      category: category,
    );
  }

  void _clearFilters() {
    context.read<TransactionProvider>().setFilters();
  }

  String _dateRangeLabel(TransactionProvider provider) {
    if (provider.startDate == null || provider.endDate == null) {
      return 'Período';
    }
    return '${provider.startDate!.day.toString().padLeft(2, '0')}/'
        '${provider.startDate!.month.toString().padLeft(2, '0')} - '
        '${provider.endDate!.day.toString().padLeft(2, '0')}/'
        '${provider.endDate!.month.toString().padLeft(2, '0')}';
  }

  Widget _buildFilterBar(TransactionProvider provider) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todas'),
                  selected: provider.category == null,
                  onSelected: (_) => _setCategory(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Depósitos'),
                  selected: provider.category == TransactionCategory.deposit,
                  onSelected: (_) => _setCategory(TransactionCategory.deposit),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Saques'),
                  selected: provider.category == TransactionCategory.withdrawal,
                  onSelected: (_) =>
                      _setCategory(TransactionCategory.withdrawal),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(_dateRangeLabel(provider)),
                  selected:
                      provider.startDate != null && provider.endDate != null,
                  onSelected: (_) => _pickDateRange(),
                ),
                if (provider.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar filtros'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Filtros: ${provider.filterSummary}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(TransactionProvider provider) {
    if (provider.loadingMore) {
      if (provider.error != null && provider.error!.contains('mais')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error!),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Tentar novamente',
                onPressed: () => provider.loadNextPage(),
              ),
            ),
          );
        });
      }
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Carregando mais transações...'),
            ],
          ),
        ),
      );
    } else if (!provider.hasMore && provider.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.grey, size: 32),
              const SizedBox(height: 12),
              Text(
                'Você atingiu o fim das transações',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildContent(TransactionProvider provider) {
    final theme = Theme.of(context);
    if (provider.loading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 12),
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: provider.loadFirstPage,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          const Center(child: Text('Nenhuma transação encontrada.')),
          if (provider.hasActiveFilters) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Limpar filtros'),
              ),
            ),
          ],
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadFirstPage,
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: (event) => _handlePointerMove(event, provider),
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerUp,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: provider.items.length + 1,
          itemBuilder: (_, index) {
            if (index == provider.items.length) {
              return _buildLoadingIndicator(provider);
            }
            final item = provider.items[index];
            return ListTile(
              leading: CircleAvatar(
                child: Icon(
                  item.isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                ),
              ),
              title: Text(
                item.description.isEmpty
                    ? (item.isDeposit ? 'Depósito' : 'Saque')
                    : item.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Text(
                'R\$ ${formatBrlCurrency(item.amount)}',
                style: AppTypography.financialCompact(
                  theme.textTheme,
                  color: item.isDeposit ? AppColors.income : AppColors.expense,
                ),
              ),
              onTap: () => Navigator.pushNamed(
                context,
                Routes.transactionForm,
                arguments: item,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        actions: [
          IconButton(
            onPressed: provider.loadFirstPage,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar transações',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(provider),
          Expanded(child: _buildContent(provider)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.transactionForm),
        child: const Icon(Icons.add),
      ),
    );
  }
}
