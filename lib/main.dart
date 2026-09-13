import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'routes.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/transactions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, auth, transactions) =>
              transactions!..setUser(auth.user?.uid),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pueblo Bank',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF075985)),
        useMaterial3: true,
      ),
      initialRoute: Routes.login,
      routes: {
        Routes.register: (context) => const RegisterScreen(),
        Routes.login: (context) => const LoginScreen(),
        Routes.dashboard: (context) => const DashboardScreen(),
        Routes.transactions: (context) => const TransactionsScreen(),
        Routes.transactionForm: (context) => const TransactionFormScreen(),
      },
    );
  }
}