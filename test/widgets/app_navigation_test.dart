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

class _FakeUser extends Fake implements User {
  @override
  String get email => 'test@example.com';

  @override
  String get uid => 'user-1';
}

class _AuthenticatedAuthService extends _FakeAuthService {
  @override
  User? get currentUser => _FakeUser();
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

  @override
  Future<String> create(String userId, TransactionModel transaction) async {
    return 'new-id';
  }
}

class _SuccessfulTransactionForm extends StatefulWidget {
  const _SuccessfulTransactionForm();

  @override
  State<_SuccessfulTransactionForm> createState() =>
      _SuccessfulTransactionFormState();
}

class _SuccessfulTransactionFormState
    extends State<_SuccessfulTransactionForm> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp({WidgetBuilder? transactionFormBuilder}) {
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
          Routes.transactionForm:
              transactionFormBuilder ?? (_) => const TransactionFormScreen(),
        },
      ),
    );
  }

  Widget buildAuthenticatedApp() {
    final transactions = TransactionProvider(service: _FakeTransactionService())
      ..setUser('user-1');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            service: _AuthenticatedAuthService(),
            biometricService: _FakeBiometricService(),
          ),
        ),
        ChangeNotifierProvider.value(value: transactions),
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

  testWidgets('abre transacoes pela acao do resumo sem perder a barra',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Ver transações'));
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

  testWidgets('restaura a origem quando a rota de nova transacao e fechada',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
          transactionFormBuilder: (_) => const _SuccessfulTransactionForm()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova transação'));
    await tester.pumpAndSettle();

    expect(find.text('Transações'), findsAtLeastNWidgets(2));
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('permanece em nova transacao apos salvar no formulario real',
      (tester) async {
    await tester.pumpWidget(buildAuthenticatedApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova transação'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '50');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar depósito'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Deseja cadastrar outra transação?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sim'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionFormScreen), findsOneWidget);
    expect(find.text('Depositado com sucesso!'), findsNothing);
    expect(find.byType(TextFormField).first, findsOneWidget);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first)
        .controller
        ?.text, isEmpty);
  });

  testWidgets('envia ao resumo ao escolher nao apos novo cadastro',
      (tester) async {
    await tester.pumpWidget(buildAuthenticatedApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova transação'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '50');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar depósito'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Deseja cadastrar outra transação?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Não'));
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.byType(TransactionFormScreen), findsNothing);
  });
}
