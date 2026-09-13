import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pueblo_bank/providers/auth_provider.dart';
import 'package:pueblo_bank/screens/login_screen.dart';
import 'package:pueblo_bank/services/auth_service.dart';

// Evita tocar FirebaseAuth.instance durante os testes de widget.
class FakeAuthService extends AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();
}

void main() {
  Widget buildApp() {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(service: FakeAuthService()),
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('mostra erro quando e-mail é inválido', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'email-invalido');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe um e-mail valido.'), findsOneWidget);
  });

  testWidgets('mostra erro quando senha é curta', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(find.byType(TextFormField).at(0), 'user@teste.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Use pelo menos seis caracteres.'), findsOneWidget);
  });
}
