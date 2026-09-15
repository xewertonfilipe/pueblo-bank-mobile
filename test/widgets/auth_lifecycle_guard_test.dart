import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pueblo_bank/providers/auth_provider.dart';
import 'package:pueblo_bank/services/auth_service.dart';
import 'package:pueblo_bank/services/biometric_service.dart';
import 'package:pueblo_bank/widgets/auth_lifecycle_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser extends Fake implements User {}

class _FakeAuthService extends AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => _FakeUser();
}

class _FakeBiometricService extends BiometricService {
  @override
  Future<bool> canUseBiometric() async => true;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('redireciona para login após retornar do segundo plano',
      (tester) async {
    final auth = AuthProvider(
      service: _FakeAuthService(),
      biometricService: _FakeBiometricService(),
    );
    await auth.enableBiometric();
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: AuthLifecycleGuard(
          navigatorKey: navigatorKey,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('conteúdo protegido')),
            routes: {
              '/login': (_) => const Scaffold(body: Text('login')),
            },
          ),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(auth.isLocked, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('conteúdo protegido'), findsNothing);
    auth.dispose();
  });

  testWidgets('não bloqueia sessão sem biometria ativada', (tester) async {
    final auth = AuthProvider(
      service: _FakeAuthService(),
      biometricService: _FakeBiometricService(),
    );
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: AuthLifecycleGuard(
          navigatorKey: navigatorKey,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text('conteúdo protegido')),
            routes: {
              '/login': (_) => const Scaffold(body: Text('login')),
            },
          ),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(auth.isLocked, isFalse);
    expect(find.text('conteúdo protegido'), findsOneWidget);
    expect(find.text('login'), findsNothing);
    auth.dispose();
  });
}
