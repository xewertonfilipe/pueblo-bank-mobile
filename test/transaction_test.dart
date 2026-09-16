import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/services/transaction_service.dart';

class FakeTransactionService extends TransactionService {
  final List<TransactionModel> storage = [];
  var createCalls = 0;

  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 20,
  }) async {
    return TransactionPage(items: List.from(storage), cursor: null);
  }

  @override
  Future<String> create(String userId, TransactionModel transaction) async {
    createCalls++;
    final id = 'id_${storage.length + 1}';
    storage.add(transaction.copyWith(id: id));
    return id;
  }
}

void main() {
  group('TransactionModel Tests', () {
    test('Calculates isDeposit correctly', () {
      final deposit = TransactionModel(
        id: '1',
        amount: 150.0,
        category: TransactionCategory.deposit,
        date: DateTime(2026, 9, 10),
      );

      final withdrawal = TransactionModel(
        id: '2',
        amount: 50.0,
        category: TransactionCategory.withdrawal,
        date: DateTime(2026, 9, 10),
      );

      expect(deposit.isDeposit, isTrue);
      expect(withdrawal.isDeposit, isFalse);
    });

    test('copyWith updates properties correctly', () {
      final item = TransactionModel(
        id: '1',
        amount: 100.0,
        category: TransactionCategory.deposit,
        date: DateTime(2026, 9, 10),
      );

      final updated = item.copyWith(
        amount: 200.0,
        description: 'Pix recebido',
      );

      expect(updated.id, '1');
      expect(updated.amount, 200.0);
      expect(updated.description, 'Pix recebido');
      expect(updated.category, TransactionCategory.deposit);
    });
  });

  group('TransactionProvider Unit Tests', () {
    test('Calculates balance, deposits and withdrawals correctly', () {
      final fakeService = FakeTransactionService();
      final provider = TransactionProvider(service: fakeService);
      expect(provider.balance, 0.0);
      expect(provider.deposits, 0.0);
      expect(provider.withdrawals, 0.0);
    });

    test('Rejects withdrawal when the summary balance is zero', () async {
      final fakeService = FakeTransactionService();
      final provider = TransactionProvider(service: fakeService);
      provider.setUser('test_user_id');

      await expectLater(
        provider.save(
          TransactionModel(
            id: '',
            amount: 50.0,
            category: TransactionCategory.withdrawal,
            date: DateTime(2026, 9, 10),
          ),
        ),
        throwsA(isA<InsufficientBalanceException>()),
      );

      expect(fakeService.createCalls, 0);
      expect(provider.items, isEmpty);
      expect(provider.summaryBalance, 0.0);
    });

    test('Saves transaction and updates balance and items', () async {
      final fakeService = FakeTransactionService();
      final provider = TransactionProvider(service: fakeService);
      provider.setUser('test_user_id');

      await provider.save(
        TransactionModel(
          id: '',
          amount: 300.0,
          category: TransactionCategory.deposit,
          date: DateTime(2026, 9, 10),
          description: 'Salário',
        ),
      );

      await provider.save(
        TransactionModel(
          id: '',
          amount: 100.0,
          category: TransactionCategory.withdrawal,
          date: DateTime(2026, 9, 10),
          description: 'Mercado',
        ),
      );

      expect(provider.items.length, 2);
      expect(provider.deposits, 300.0);
      expect(provider.withdrawals, 100.0);
      expect(provider.balance, 200.0);
    });
  });
}
