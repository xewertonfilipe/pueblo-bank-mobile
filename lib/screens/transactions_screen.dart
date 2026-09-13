import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../routes.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300) context.read<TransactionProvider>().loadNextPage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<TransactionProvider>();
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: provider.startDate == null || provider.endDate == null ? null : DateTimeRange(start: provider.startDate!, end: provider.endDate!));
    if (range != null) provider.setFilters(startDate: range.start, endDate: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59), category: provider.category);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => provider.setFilters(
              startDate: provider.startDate,
              endDate: provider.endDate,
              category: value == 'all'
                  ? null
                  : value == 'deposit'
                      ? TransactionCategory.deposit
                      : TransactionCategory.withdrawal,
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('Todas')),
              PopupMenuItem(value: 'deposit', child: Text('Depósitos')),
              PopupMenuItem(value: 'withdrawal', child: Text('Saques')),
            ],
          ),
        ],
      ),
      body: provider.loading && provider.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.items.isEmpty
              ? Center(child: Text(provider.error!))
              : RefreshIndicator(
                  onRefresh: provider.loadFirstPage,
                  child: provider.items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 240),
                            Center(child: Text('Nenhuma transação encontrada.')),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: provider.items.length + (provider.loadingMore ? 1 : 0),
                          itemBuilder: (_, index) {
                            if (index == provider.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
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
                              ),
                              subtitle: Text(
                                '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year}',
                              ),
                              trailing: Text(
                                'R\$ ${item.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: item.isDeposit ? Colors.green : Colors.red,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.transactionForm),
        child: const Icon(Icons.add),
      ),
    );
  }
}
