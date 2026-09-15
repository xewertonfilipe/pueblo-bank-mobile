import 'package:flutter/material.dart';

import '../routes.dart';
import '../screens/dashboard_screen.dart';
import '../screens/transactions_screen.dart';

class AppNavigationScreen extends StatefulWidget {
  const AppNavigationScreen({super.key});

  @override
  State<AppNavigationScreen> createState() => _AppNavigationScreenState();
}

class _AppNavigationScreenState extends State<AppNavigationScreen> {
  int _selectedIndex = 0;
  int _contentIndex = 0;

  Future<void> _openNewTransaction() async {
    final previousIndex = _contentIndex;
    setState(() => _selectedIndex = 2);
    await Navigator.pushNamed(context, Routes.transactionForm);
    if (!mounted) return;
    setState(() {
      _contentIndex = previousIndex;
      _selectedIndex = previousIndex;
    });
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _contentIndex,
        children: const [
          DashboardScreen(),
          TransactionsScreen(),
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
