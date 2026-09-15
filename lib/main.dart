import 'package:firebase_app_check/firebase_app_check.dart';
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
import 'screens/splash_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/transactions_screen.dart';
import 'widgets/auth_lifecycle_guard.dart';

// Usado pelo Dashboard para saber quando volta a ficar visível na pilha de rotas.
final routeObserver = RouteObserver<PageRoute<dynamic>>();
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<void> _bootstrapFuture;
  bool _appCheckActivated = false;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (!_appCheckActivated) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidDebugProvider(),
      );
      _appCheckActivated = true;
    }
  }

  void _retryBootstrap() {
    setState(() => _bootstrapFuture = _initializeFirebase());
  }

  Widget _buildBootstrapScreen(AsyncSnapshot<void> snapshot) {
    return MaterialApp(
      title: 'Pueblo Bank',
      home: SplashScreen(
        error: snapshot.hasError
            ? 'Não foi possível conectar. Verifique sua internet e tente novamente.'
            : null,
        onRetry: snapshot.hasError ? _retryBootstrap : null,
      ),
    );
  }

  Widget _buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, auth, transactions) =>
              transactions!..setUser(auth.user?.uid),
        ),
      ],
      child: AuthLifecycleGuard(
        navigatorKey: navigatorKey,
        child: const MyApp(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError) {
          return _buildBootstrapScreen(snapshot);
        }
        return _buildApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Pueblo Bank',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF075985)),
        useMaterial3: true,
      ),
      navigatorObservers: [routeObserver],
      initialRoute: Routes.login,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.login: (context) => const LoginScreen(),
        Routes.dashboard: (context) => const DashboardScreen(),
        Routes.transactions: (context) => const TransactionsScreen(),
        Routes.transactionForm: (context) => const TransactionFormScreen(),
      },
    );
  }
}
