import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({TransactionService? service}) : _service = service ?? TransactionService();

  final TransactionService _service;
  String? _userId;
  List<TransactionModel> _items = [];
  List<TransactionModel> _summaryItems = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  DateTime? _startDate;
  DateTime? _endDate;
  TransactionCategory? _category;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  List<TransactionModel> get items => List.unmodifiable(_items);
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  TransactionCategory? get category => _category;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  double get deposits => _items.where((item) => item.isDeposit).fold<double>(0.0, (acc, item) => acc + item.amount);
  double get withdrawals => _items.where((item) => !item.isDeposit).fold<double>(0.0, (acc, item) => acc + item.amount);
  double get balance => deposits - withdrawals;

  // Dados sem filtro, usados pelo Dashboard para não refletir os filtros da tela de Transações.
  List<TransactionModel> get summaryItems => List.unmodifiable(_summaryItems);
  double get summaryDeposits => _summaryItems.where((item) => item.isDeposit).fold<double>(0.0, (acc, item) => acc + item.amount);
  double get summaryWithdrawals => _summaryItems.where((item) => !item.isDeposit).fold<double>(0.0, (acc, item) => acc + item.amount);
  double get summaryBalance => summaryDeposits - summaryWithdrawals;

  void setUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _items = [];
    _summaryItems = [];
    _cursor = null;
    _hasMore = true;
    if (userId != null) {
      loadFirstPage();
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    if (_userId == null) return;
    try {
      final page = await _service.fetchPage(userId: _userId!, limit: 1000);
      _summaryItems = page.items;
      notifyListeners();
    } catch (_) {
      // Mantem o resumo anterior em caso de falha pontual.
    }
  }

  Future<void> loadFirstPage() async {
    if (_userId == null) return;
    _loading = true;
    _error = null;
    _cursor = null;
    _hasMore = true;
    notifyListeners();
    try {
      final page = await _service.fetchPage(userId: _userId!, startDate: _startDate, endDate: _endDate, category: _category);
      _items = page.items;
      _cursor = page.cursor;
      _hasMore = page.items.isNotEmpty && page.items.length == 20;
    } catch (_) {
      _error = 'Não foi possível carregar as transações.';
      _items = [];
      _cursor = null;
      _hasMore = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (_userId == null || !_hasMore || _loading || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _service.fetchPage(userId: _userId!, startDate: _startDate, endDate: _endDate, category: _category, cursor: _cursor);
      _items = [..._items, ...page.items];
      _cursor = page.cursor;
      _hasMore = page.items.isNotEmpty && page.items.length == 20;
    } catch (_) {
      _error = 'Não foi possível carregar mais transações.';
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void setFilters({DateTime? startDate, DateTime? endDate, TransactionCategory? category}) {
    _startDate = startDate;
    _endDate = endDate;
    _category = category;
    loadFirstPage();
  }

  Future<void> save(TransactionModel transaction) async {
    if (_userId == null) return;
    if (transaction.id.isEmpty) {
      final id = await _service.create(_userId!, transaction);
      _items = [transaction.copyWith(id: id), ..._items];
    } else {
      await _service.update(_userId!, transaction);
      _items = _items.map((item) => item.id == transaction.id ? transaction : item).toList();
    }
    notifyListeners();
    await _loadSummary();
  }

  Future<void> remove(String id) async {
    if (_userId == null) return;
    await _service.delete(_userId!, id);
    _items = _items.where((item) => item.id != id).toList();
    notifyListeners();
    await _loadSummary();
  }
}
