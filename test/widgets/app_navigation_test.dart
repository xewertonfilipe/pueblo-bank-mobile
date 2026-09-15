import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pueblo_bank/models/transaction_model.dart';
import 'package:pueblo_bank/providers/auth_provider.dart';
import 'package:pueblo_bank/providers/transaction_provider.dart';
import 'package:pueblo_bank/screens/transaction_form_screen.dart';
import 'package:pueblo_bank/routes.dart';
import 'package:pueblo_bank/services/auth_service.dart';
import 'package:pueblo_bank/services/biometric_service.dart';
import 'package:pueblo_bank/services/transaction_service.dart';
import 'package:pueblo_bank/widgets/app_navigation.dart';
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
    return const TransactionPage(items: [], cursor: null);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            service: _FakeAuthService(),
            biometricService: _FakeBiometricService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              TransactionProvider(service: _FakeTransactionService()),
        ),
      ],
      child: MaterialApp(
        home: const AppNavigationScreen(),
        routes: {
          Routes.transactionForm: (_) => const TransactionFormScreen(),
        },
      ),
    );
  }

  testWidgets('alterna entre resumo e transacoes', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Visão geral'), findsOneWidget);

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();

    expect(find.text('Transações'), findsAtLeastNWidgets(2));
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('abre nova transacao pelo destino de adicao', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova transação'));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(find.text('Nova transação'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Visão geral'), findsOneWidget);
  });
}
