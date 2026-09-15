import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../app_typography.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../routes.dart';
import '../utils/brl_currency.dart';
import '../widgets/app_feedback.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.onTransactionSaved});

  final VoidCallback? onTransactionSaved;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<TransactionProvider>()
          .setFilters(startDate: null, endDate: null, category: null);
    });
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
        AppFeedback.showInfo(context, 'Não há mais transações para carregar.');
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

  Future<void> _confirmDelete(TransactionModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: const Text(
          'Essa ação remove o registro financeiro permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<TransactionProvider>().remove(item.id);
      if (mounted) AppFeedback.showSuccess(context, 'Transação excluída.');
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, 'Não foi possível excluir a transação.');
      }
    }
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

  Future<void> _openTransactionForm({TransactionModel? transaction}) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.transactionForm,
      arguments: transaction,
    );
    if (mounted && result == true) widget.onTransactionSaved?.call();
  }

  Widget _buildFilterBar(TransactionProvider provider) {
    final theme = Theme.of(context);
    final filtersEnabled = !provider.loading;
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
                  onSelected: filtersEnabled ? (_) => _setCategory(null) : null,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Depósitos'),
                  selected: provider.category == TransactionCategory.deposit,
                  onSelected: filtersEnabled
                      ? (_) => _setCategory(TransactionCategory.deposit)
                      : null,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Saques'),
                  selected: provider.category == TransactionCategory.withdrawal,
                  onSelected: filtersEnabled
                      ? (_) => _setCategory(TransactionCategory.withdrawal)
                      : null,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(_dateRangeLabel(provider)),
                  selected:
                      provider.startDate != null && provider.endDate != null,
                  onSelected: filtersEnabled ? (_) => _pickDateRange() : null,
                ),
                if (provider.hasActiveFilters || provider.loading) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: filtersEnabled ? _clearFilters : null,
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
          if (provider.loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(TransactionProvider provider) {
    if (provider.loadingMore) {
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
    } else if (provider.error != null && provider.items.isNotEmpty) {
      return AppFeedbackPanel(
        icon: Icons.cloud_off,
        color: AppColors.error,
        title: provider.error!,
        actionLabel: 'Tentar novamente',
        onAction: provider.loadNextPage,
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

  Widget _buildTransactionTile(
    BuildContext context,
    ThemeData theme,
    TransactionModel item,
  ) {
    final typeLabel = item.isDeposit ? 'Depósito' : 'Saque';
    final description = item.description.isEmpty ? typeLabel : item.description;
    final dateLabel =
        '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}';
    final amountLabel = 'R\$ ${formatBrlCurrency(item.amount)}';

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '$description, $typeLabel, Data $dateLabel, Valor $amountLabel',
      child: ListTile(
        leading: CircleAvatar(
          child: Semantics(
            label: typeLabel,
            excludeSemantics: true,
            child: Icon(
              item.isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
            ),
          ),
        ),
        title: Text(
          description,
          style: theme.textTheme.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Semantics(
          label: 'Data $dateLabel',
          excludeSemantics: true,
          child: Text(
            dateLabel,
            style: theme.textTheme.bodySmall,
          ),
        ),
        trailing: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.48,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    label: 'Valor $amountLabel',
                    excludeSemantics: true,
                    child: Text(
                      amountLabel,
                      style: AppTypography.financialCompact(
                        theme.textTheme,
                        color: item.isDeposit
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                child: PopupMenuButton<String>(
                  tooltip: 'Ações',
                  padding: EdgeInsets.zero,
                  onSelected: (action) {
                    if (action == 'edit') {
                      _openTransactionForm(transaction: item);
                    } else {
                      _confirmDelete(item);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Excluir'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () => _openTransactionForm(transaction: item),
      ),
    );
  }

  Widget _buildContent(TransactionProvider provider) {
    final theme = Theme.of(context);
    if (provider.loading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.items.isEmpty) {
      return Center(
        child: AppFeedbackPanel(
          icon: Icons.cloud_off,
          color: AppColors.error,
          title: provider.error!,
          actionLabel: 'Tentar novamente',
          onAction: provider.loadFirstPage,
        ),
      );
    }
    if (provider.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadFirstPage,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            AppFeedbackPanel(
              icon: Icons.receipt_long_outlined,
              title: provider.hasActiveFilters
                  ? 'Nenhuma transação encontrada para estes filtros.'
                  : 'Ainda não há transações para exibir.',
              actionLabel: provider.hasActiveFilters ? 'Limpar filtros' : null,
              onAction: provider.hasActiveFilters ? _clearFilters : null,
              actionIcon: Icons.clear,
            ),
          ],
        ),
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
            return _buildTransactionTile(context, theme, provider.items[index]);
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
            onPressed: provider.loading ? null : provider.loadFirstPage,
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
    );
  }
}
