import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/widgets/app_feedback.dart';

void main() {
  testWidgets('executa a ação do painel de feedback', (tester) async {
    var actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFeedbackPanel(
            icon: Icons.cloud_off,
            title: 'Não foi possível carregar.',
            actionLabel: 'Tentar novamente',
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tentar novamente'));

    expect(actionCalled, isTrue);
    expect(
      find.bySemanticsLabel('Não foi possível carregar.'),
      findsOneWidget,
    );
  });

  testWidgets('exibe erro e sucesso com feedback semantico', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () =>
                      AppFeedback.showError(context, 'Falha ao salvar.'),
                  child: const Text('Mostrar erro'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      AppFeedback.showSuccess(context, 'Salvo com sucesso.'),
                  child: const Text('Mostrar sucesso'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar erro'));
    await tester.pump();
    expect(find.text('Falha ao salvar.'), findsOneWidget);

    await tester.tap(find.text('Mostrar sucesso'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Salvo com sucesso.'), findsOneWidget);
  });
}
