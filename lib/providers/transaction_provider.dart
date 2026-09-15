import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  static const _minimumSummaryRefresh = Duration(milliseconds: 350);

  TransactionProvider({TransactionService? service})
      : _service = service ?? TransactionService();

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
  bool _summaryLoading = false;
  Future<void>? _summaryRefreshInFlight;
  DateTime? _summaryUpdatedAt;
  bool _needsSummaryRefresh = false;
  bool _shouldScrollToTop = false;
  String? _error;

  List<TransactionModel> get items => List.unmodifiable(_items);
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  TransactionCategory? get category => _category;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get summaryLoading => _summaryLoading;
  DateTime? get summaryUpdatedAt => _summaryUpdatedAt;
  bool get shouldScrollToTop => _shouldScrollToTop;
  String? get error => _error;
  bool get hasActiveFilters =>
      _startDate != null || _endDate != null || _category != null;

  String get filterSummary {
    final filters = <String>[];
    if (_category == TransactionCategory.deposit) filters.add('Depósitos');
    if (_category == TransactionCategory.withdrawal) filters.add('Saques');
    if (_startDate != null && _endDate != null) {
      filters.add('${_formatDate(_startDate!)} a ${_formatDate(_endDate!)}');
    }
    return filters.isEmpty ? 'Todas as transações' : filters.join(' · ');
  }

  void clearScrollFlag() {
    _shouldScrollToTop = false;
  }

  double get deposits => _items
      .where((item) => item.isDeposit)
      .fold<double>(0.0, (acc, item) => acc + item.amount);
  double get withdrawals => _items
      .where((item) => !item.isDeposit)
      .fold<double>(0.0, (acc, item) => acc + item.amount);
  double get balance => deposits - withdrawals;

  List<TransactionModel> get summaryItems => List.unmodifiable(_summaryItems);
  double get summaryDeposits => _summaryItems
      .where((item) => item.isDeposit)
      .fold<double>(0.0, (acc, item) => acc + item.amount);
  double get summaryWithdrawals => _summaryItems
      .where((item) => !item.isDeposit)
      .fold<double>(0.0, (acc, item) => acc + item.amount);
  double get summaryBalance => summaryDeposits - summaryWithdrawals;

  void setUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _items = [];
    _summaryItems = [];
    _summaryUpdatedAt = null;
    _cursor = null;
    _hasMore = true;
    if (userId != null) {
      loadFirstPage();
      _loadSummary();
    }
  }

  Future<void> _loadSummary({Duration minimumDuration = Duration.zero}) async {
    if (_userId == null) return;
    final loadingStartedAt = Stopwatch()..start();
    _summaryLoading = true;
    notifyListeners();
    try {
      final page = await _service.fetchPage(userId: _userId!, limit: 1000);
      _summaryItems = page.items;
      _summaryUpdatedAt = DateTime.now();
    } catch (_) {
    } finally {
      final remaining = minimumDuration - loadingStartedAt.elapsed;
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      _summaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSummaryIfNeeded() async {
    final inFlight = _summaryRefreshInFlight;
    if (inFlight != null) {
      return;
    }
    if (!_needsSummaryRefresh) return;
    _needsSummaryRefresh = false;
    final refresh = _loadSummary(minimumDuration: _minimumSummaryRefresh);
    _summaryRefreshInFlight = refresh;
    try {
      await refresh;
    } finally {
      _summaryRefreshInFlight = null;
    }
  }

  Future<void> loadFirstPage() async {
    if (_userId == null || _loading) return;
    _loading = true;
    _error = null;
    _cursor = null;
    _hasMore = true;
    notifyListeners();
    try {
      final page = await _service.fetchPage(
          userId: _userId!,
          startDate: _startDate,
          endDate: _endDate,
          category: _category);
      _items = page.items;
      _cursor = page.cursor;
      _hasMore = page.items.length >= 10;
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
    _error = null;
    notifyListeners();
    try {
      final page = await _service.fetchPage(
          userId: _userId!,
          startDate: _startDate,
          endDate: _endDate,
          category: _category,
          cursor: _cursor);
      _items = [..._items, ...page.items];
      _cursor = page.cursor;
      _hasMore = page.items.length >= 10;
    } catch (_) {
      _error = 'Não foi possível carregar mais transações.';
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void setFilters(
      {DateTime? startDate, DateTime? endDate, TransactionCategory? category}) {
    _startDate = startDate;
    _endDate = endDate;
    _category = category;
    loadFirstPage();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> save(TransactionModel transaction) async {
    if (_userId == null) return;
    if (transaction.createdAt == null) {
      final id = await _service.create(_userId!, transaction);
      _items = [
        transaction.copyWith(id: id, createdAt: DateTime.now()),
        ..._items
      ];
    } else {
      await _service.update(_userId!, transaction);
      _items = _items
          .map((item) => item.id == transaction.id ? transaction : item)
          .toList();
    }
    _needsSummaryRefresh = true;
    _shouldScrollToTop = true;
    notifyListeners();
  }

  Future<void> remove(String id) async {
    if (_userId == null) return;
    await _service.delete(_userId!, id);
    _items = _items.where((item) => item.id != id).toList();
    _needsSummaryRefresh = true;
    notifyListeners();
  }
}
