import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pueblo_bank/providers/auth_provider.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/screens/dashboard_screen.dart';
import 'package:pueblo_bank/services/auth_service.dart';
import 'package:pueblo_bank/services/biometric_service.dart';
import 'package:pueblo_bank/services/transaction_service.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthService extends AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;
}

class _FakeBiometricService extends BiometricService {
  @override
  Future<bool> canUseBiometric() async => false;
}

class _FakeTransactionService extends TransactionService {
  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 10,
  }) async {
    return TransactionPage(
      items: [
        TransactionModel(
          id: 'deposit-1',
          amount: 100,
          category: TransactionCategory.deposit,
          date: DateTime(2026, 9, 14),
          description: 'Entrada',
        ),
        TransactionModel(
          id: 'withdrawal-1',
          amount: 25,
          category: TransactionCategory.withdrawal,
          date: DateTime(2026, 9, 13),
          description: 'Saída',
        ),
      ],
      cursor: null,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('exibe depósitos em verde e saques em vermelho', (tester) async {
    final transactionProvider =
        TransactionProvider(service: _FakeTransactionService());
    transactionProvider.setUser('user-1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              service: _FakeAuthService(),
              biometricService: _FakeBiometricService(),
            ),
          ),
          ChangeNotifierProvider.value(value: transactionProvider),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();

    final deposit = tester.widget<Text>(find.text('R\$ 100.00'));
    final withdrawal = tester.widget<Text>(find.text('R\$ 25.00'));

    expect(deposit.style?.color, Colors.green);
    expect(withdrawal.style?.color, Colors.red);
    expect(find.text('Entrada'), findsOneWidget);
    expect(find.text('Saída'), findsOneWidget);
  });
}
