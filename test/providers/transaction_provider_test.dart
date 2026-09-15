import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/services/transaction_service.dart';

class MockTransactionService extends Mock implements TransactionService {}

class FakeTransactionModel extends Fake implements TransactionModel {}

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
}
