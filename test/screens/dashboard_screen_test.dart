import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pueblo_bank/providers/auth_provider.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/screens/dashboard_screen.dart';
import 'package:pueblo_bank/screens/transaction_form_screen.dart';
import 'package:pueblo_bank/routes.dart';
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
          amount: 1234.56,
          category: TransactionCategory.deposit,
          date: DateTime(2026, 9, 14),
          description: 'Entrada',
        ),
        TransactionModel(
          id: 'withdrawal-1',
          amount: 234.56,
          category: TransactionCategory.withdrawal,
          date: DateTime(2026, 9, 13),
          description: 'Saída',
        ),
      ],
      cursor: null,
    );
  }
}

class _EmptyTransactionService extends TransactionService {
  @override
  Future<TransactionPage> fetchPage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    dynamic cursor,
    int limit = 10,
  }) async {
    return const TransactionPage(items: [], cursor: null);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('exibe recentes com cores e abre a edição ao tocar',
      (tester) async {
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
        child: MaterialApp(
          home: const DashboardScreen(),
          routes: {
            Routes.transactionForm: (_) => const TransactionFormScreen(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();

    final deposit = tester.widget<Text>(find.text('R\$ 1.234,56'));
    final withdrawal = tester.widget<Text>(find.text('R\$ 234,56'));

    expect(deposit.style?.color, Colors.green);
    expect(withdrawal.style?.color, Colors.red);
    expect(find.text('Entrada'), findsOneWidget);
    expect(find.text('Saída'), findsOneWidget);

    await tester.tap(find.text('Entrada'));
    await tester.pumpAndSettle();

    expect(find.text('Editar transação'), findsOneWidget);
  });

  testWidgets('exibe estado vazio com ação para nova transação',
      (tester) async {
    final transactionProvider =
        TransactionProvider(service: _EmptyTransactionService());
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
        child: MaterialApp(
          home: const DashboardScreen(),
          routes: {
            Routes.transactionForm: (_) => const TransactionFormScreen(),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(transactionProvider.summaryLoading, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump();

    expect(find.text('Ainda não há transações para exibir.'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Nova transação'));
    await tester.pumpAndSettle();

    expect(find.text('Nova transação'), findsOneWidget);
  });
}
