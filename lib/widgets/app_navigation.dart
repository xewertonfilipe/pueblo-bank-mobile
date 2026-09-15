import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../routes.dart';
import '../screens/dashboard_screen.dart';
import '../screens/transaction_form_screen.dart';
import '../screens/transactions_screen.dart';

class AppNavigationScreen extends StatefulWidget {
  const AppNavigationScreen({super.key});

  @override
  State<AppNavigationScreen> createState() => _AppNavigationScreenState();
}

class _AppNavigationScreenState extends State<AppNavigationScreen> {
  int _selectedIndex = 0;
  int _contentIndex = 0;
  bool _summaryNavigationScheduled = false;

  void _showSummaryAfterSave() {
    if (!mounted || _summaryNavigationScheduled) return;
    _summaryNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _summaryNavigationScheduled = false;
      if (!mounted) return;
      setState(() {
        _contentIndex = 0;
        _selectedIndex = 0;
      });
      context.read<TransactionProvider>().refreshSummaryIfNeeded();
    });
  }

  void _showTransactions() {
    if (!mounted) return;
    setState(() {
      _contentIndex = 1;
      _selectedIndex = 1;
    });
  }

  Future<void> _openNewTransaction() async {
    final previousIndex = _contentIndex;
    setState(() => _selectedIndex = 2);
    final result = await Navigator.pushNamed(
      context,
      Routes.transactionForm,
      arguments: const TransactionFormArguments(
        source: TransactionFormSource.newTransaction,
      ),
    );
    if (!mounted) return;
    if (result == true || result == null) {
      setState(() {
        _contentIndex = previousIndex;
        _selectedIndex = previousIndex;
      });
    }
  }

  void _selectDestination(int index) {
    if (index == 2) {
      _openNewTransaction();
      return;
    }
    setState(() {
      _selectedIndex = index;
      _contentIndex = index;
    });
    if (index == 0) {
      context.read<TransactionProvider>().refreshSummaryIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _contentIndex,
        children: [
          DashboardScreen(
            isActive: _contentIndex == 0,
            onTransactionSaved: _showSummaryAfterSave,
            onViewTransactions: _showTransactions,
          ),
          const TransactionsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Resumo',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transações',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Nova transação',
          ),
        ],
      ),
    );
  }
}
