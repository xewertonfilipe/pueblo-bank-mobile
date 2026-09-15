import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pueblo_bank/providers/auth_provider.dart';
import 'package:pueblo_bank/screens/login_screen.dart';
import 'package:pueblo_bank/services/auth_service.dart';
import 'package:pueblo_bank/services/biometric_service.dart';
import 'package:pueblo_bank/utils/auth_validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthService extends AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;
}

class FakeBiometricService extends BiometricService {
  @override
  Future<bool> canUseBiometric() async => false;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildApp() {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(
          service: FakeAuthService(), biometricService: FakeBiometricService()),
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('mostra erro quando e-mail é inválido', (tester) async {
    await tester.pumpWidget(buildApp());
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }

    await tester.enterText(find.byType(TextFormField).at(0), 'email-invalido');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail valido.'), findsOneWidget);
  });

  testWidgets('mostra erro quando senha é curta', (tester) async {
    await tester.pumpWidget(buildApp());
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }

    await tester.enterText(find.byType(TextFormField).at(0), 'user@teste.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Use pelo menos seis caracteres.'), findsOneWidget);
  });

  testWidgets('limita o e-mail a 254 caracteres', (tester) async {
    await tester.pumpWidget(buildApp());
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }

    final emailField = find.byType(TextFormField).at(0);
    await tester.enterText(emailField, 'a' * 300);

    final field = tester.widget<TextFormField>(emailField);
    expect(field.controller!.text.length, emailMaxLength);
  });

  testWidgets('rejeita e-mail sem extensão de domínio', (tester) async {
    await tester.pumpWidget(buildApp());
    for (var i = 0; i < 6; i++) {
      await tester.pump();
    }

    await tester.enterText(find.byType(TextFormField).at(0), 'user@dominio');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail valido.'), findsOneWidget);
  });
}
