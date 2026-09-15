import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/services/transaction_service.dart';

class MockTransactionService extends Mock implements TransactionService {}

class FakeTransactionModel extends Fake implements TransactionModel {}

class _PaginationTransactionService extends TransactionService {
  var _pageCalls = 0;

  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 10,
  }) async {
    if (limit == 1000) return const TransactionPage(items: [], cursor: null);
    if (_pageCalls++ == 0) {
      return TransactionPage(
        items: List.generate(
          10,
          (index) => TransactionModel(
            id: 'transaction-$index',
            amount: 10,
            category: TransactionCategory.deposit,
            date: DateTime(2026, 1, 1),
          ),
        ),
        cursor: null,
      );
    }
    if (_pageCalls == 2) throw StateError('pagination failed');
    return const TransactionPage(items: [], cursor: null);
  }
}

class _FilterLoadingService extends TransactionService {
  var calls = 0;
  TransactionCategory? requestedCategory;
  final pendingPage = Completer<TransactionPage>();

  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 10,
  }) async {
    requestedCategory = category;
    calls++;
    if (calls == 1) {
      return TransactionPage(
        items: [
          TransactionModel(
            id: 'initial-1',
            amount: 100,
            category: TransactionCategory.deposit,
            date: DateTime(2026, 9, 14),
          ),
        ],
        cursor: null,
      );
    }
    return pendingPage.future;
  }
}

class _SummaryRefreshService extends TransactionService {
  var summaryCalls = 0;
  final pendingSummary = Completer<TransactionPage>();

  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 10,
  }) async {
    if (limit != 1000) {
      return const TransactionPage(items: [], cursor: null);
    }
    summaryCalls++;
    if (summaryCalls == 1) {
      return const TransactionPage(items: [], cursor: null);
    }
    return pendingSummary.future;
  }

  @override
  Future<String> create(String userId, TransactionModel transaction) async {
    return 'new-id';
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTransactionModel());
  });

  late MockTransactionService service;
  late TransactionProvider provider;

  final sampleTransaction = TransactionModel(
    id: '1',
    amount: 100,
    category: TransactionCategory.deposit,
    date: DateTime(2026, 1, 1),
  );

  setUp(() {
    service = MockTransactionService();
    provider = TransactionProvider(service: service);
  });

  test('loadFirstPage popula items a partir do service', () async {
    when(() => service.fetchPage(
              userId: any(named: 'userId'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            ))
        .thenAnswer((_) async =>
            TransactionPage(items: [sampleTransaction], cursor: null));

    provider.setUser('user-1');
    await provider.loadFirstPage();

    expect(provider.items, hasLength(1));
    expect(provider.items.first.id, '1');
  });

  test('save() cria nova transação e marca refresh/scroll pendentes', () async {
    when(() => service.fetchPage(
              userId: any(named: 'userId'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            ))
        .thenAnswer(
            (_) async => const TransactionPage(items: [], cursor: null));
    when(() => service.create(any(), any())).thenAnswer((_) async => 'new-id');

    provider.setUser('user-1');
    await provider.loadFirstPage();

    final newTransaction = TransactionModel(
      id: '',
      amount: 50,
      category: TransactionCategory.deposit,
      date: DateTime(2026, 1, 2),
    );
    await provider.save(newTransaction);

    verify(() => service.create('user-1', any())).called(1);
    expect(provider.shouldScrollToTop, isTrue);
  });

  test('refresha o resumo uma vez após salvar e expõe loading', () async {
    final summaryService = _SummaryRefreshService();
    final summaryProvider = TransactionProvider(service: summaryService);

    summaryProvider.setUser('user-1');
    await Future<void>.delayed(Duration.zero);

    await summaryProvider.save(
      TransactionModel(
        id: '',
        amount: 50,
        category: TransactionCategory.deposit,
        date: DateTime(2026, 1, 2),
      ),
    );

    final refresh = summaryProvider.refreshSummaryIfNeeded();
    expect(summaryProvider.summaryLoading, isTrue);
    expect(summaryService.summaryCalls, 2);

    await summaryProvider.refreshSummaryIfNeeded();
    expect(summaryService.summaryCalls, 2);

    summaryService.pendingSummary.complete(
      TransactionPage(
        items: [
          TransactionModel(
            id: 'new-id',
            amount: 50,
            category: TransactionCategory.deposit,
            date: DateTime(2026, 1, 2),
          ),
        ],
        cursor: null,
      ),
    );
    await refresh;

    expect(summaryProvider.summaryLoading, isFalse);
    expect(summaryProvider.summaryItems, hasLength(1));
    expect(summaryProvider.summaryBalance, 50);
  });

  test('remove() exclui transação existente', () async {
    when(() => service.fetchPage(
              userId: any(named: 'userId'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
              category: any(named: 'category'),
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            ))
        .thenAnswer((_) async =>
            TransactionPage(items: [sampleTransaction], cursor: null));
    when(() => service.delete(any(), any())).thenAnswer((_) async {});

    provider.setUser('user-1');
    await provider.loadFirstPage();

    await provider.remove('1');

    verify(() => service.delete('user-1', '1')).called(1);
    expect(provider.items, isEmpty);
  });

  test('expõe resumo dos filtros ativos', () {
    final startDate = DateTime(2026, 9, 1);
    final endDate = DateTime(2026, 9, 15);

    provider.setFilters(
      startDate: startDate,
      endDate: endDate,
      category: TransactionCategory.deposit,
    );

    expect(provider.hasActiveFilters, isTrue);
    expect(provider.filterSummary, 'Depósitos · 01/09/2026 a 15/09/2026');

    provider.setFilters();

    expect(provider.hasActiveFilters, isFalse);
    expect(provider.filterSummary, 'Todas as transações');
  });

  test('mantém itens e loading durante a troca de filtro', () async {
    final filterService = _FilterLoadingService();
    final filterProvider = TransactionProvider(service: filterService);

    filterProvider.setUser('user-1');
    await Future<void>.delayed(Duration.zero);
    expect(filterProvider.items, hasLength(1));

    filterProvider.setFilters(category: TransactionCategory.withdrawal);

    expect(filterProvider.loading, isTrue);
    expect(filterProvider.items, hasLength(1));
    expect(filterService.requestedCategory, TransactionCategory.withdrawal);

    filterService.pendingPage
        .complete(const TransactionPage(items: [], cursor: null));
    await Future<void>.delayed(Duration.zero);

    expect(filterProvider.loading, isFalse);
    expect(filterProvider.items, isEmpty);
  });

  test('preserva itens ao falhar na paginação e limpa erro no retry', () async {
    final paginationProvider =
        TransactionProvider(service: _PaginationTransactionService());

    paginationProvider.setUser('user-1');
    await Future<void>.delayed(Duration.zero);

    expect(paginationProvider.items, hasLength(10));

    await paginationProvider.loadNextPage();

    expect(paginationProvider.items, hasLength(10));
    expect(
        paginationProvider.error, 'Não foi possível carregar mais transações.');

    await paginationProvider.loadNextPage();

    expect(paginationProvider.items, hasLength(10));
    expect(paginationProvider.error, isNull);
    expect(paginationProvider.hasMore, isFalse);
  });
}
