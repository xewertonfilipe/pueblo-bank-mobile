# Pueblo Bank - Contexto do Projeto

Data do registro: 2026-09-10

## Objetivo

Aplicativo Flutter mobile para gerenciamento financeiro, baseado na estrutura do projeto didatico `aula5/5.4/image_gallery_app`, mas criado como um novo projeto independente em `pueblo_bank/`.

A versao da aula 5.4 deve permanecer preservada e nao deve ser alterada.

## Requisitos cobertos pelo planejamento

- Login e cadastro com e-mail e senha.
- Dashboard com saldo, depositos, saques e analises.
- Grafico de evolucao financeira usando `fl_chart` com `LineChart`.
- Grafico de distribuicao por categoria usando `fl_chart` com `PieChart`.
- Listagem de transacoes.
- Filtros por periodo e categoria: deposito ou saque.
- Paginacao por cursor do Cloud Firestore.
- Criacao e edicao de transacoes.
- Validacao de valor e categoria.
- Upload de recibos no Firebase Storage.
- Estado global com Provider e `ChangeNotifier`.
- Regras de seguranca por usuario.

## Estrutura atual

```text
pueblo_bank/
  lib/
    main.dart
    routes.dart
    app_colors.dart
    models/
      transaction_model.dart
    providers/
      auth_provider.dart
      transaction_provider.dart
    services/
      auth_service.dart
      transaction_service.dart
      storage_service.dart
    screens/
      login_screen.dart
      register_screen.dart
      dashboard_screen.dart
      transactions_screen.dart
      transaction_form_screen.dart
    widgets/
      financial_summary.dart
      category_distribution_chart.dart
      financial_evolution_chart.dart
  firestore.rules
  storage.rules
  pubspec.yaml
  README.md
```

## Decisoes tecnicas

- Dependencias de runtime ficam em `dependencies` no `pubspec.yaml`.
- Bibliotecas principais: Firebase, Provider, `image_picker` e `fl_chart`.
- Transacoes: `users/{uid}/transactions/{transactionId}`.
- Recibos: `receipts/{uid}/{transactionId}/{fileName}`.
- O acesso ao Firebase fica nos services; as telas usam providers.
- A paginação usa `startAfterDocument`.
- O saldo e calculado como depositos menos saques.
- O app esta focado em Android/iOS; web e desktop nao sao prioridade.
- O `google-services.json` copiado da aula foi removido. Nao reutilizar credenciais da aula.

## Arquivos importantes

- `lib/main.dart`: inicializacao do Firebase, providers e rotas.
- `lib/models/transaction_model.dart`: modelo e conversao Firestore.
- `lib/providers/auth_provider.dart`: estado da autenticacao.
- `lib/providers/transaction_provider.dart`: filtros, paginacao e CRUD em memoria.
- `lib/services/transaction_service.dart`: consultas e operacoes Firestore.
- `lib/services/storage_service.dart`: upload e exclusao de recibos.
- `lib/screens/dashboard_screen.dart`: resumo e graficos.
- `lib/screens/transactions_screen.dart`: listagem, filtros e paginacao.
- `lib/screens/transaction_form_screen.dart`: criacao, edicao e recibo.
- `firestore.rules` e `storage.rules`: isolamento por usuario.
- `README.md`: configuracao local resumida.

## Estado atual

Implementado:

- Scaffold independente criado na raiz.
- Identidade do pacote Flutter alterada para `pueblo_bank`.
- Identificador Android definido como `pueblo.bank`.
- Autenticacao integrada ao `AuthProvider`.
- Modelo, services e providers financeiros criados.
- Dashboard, graficos, listagem e formulario criados.
- Regras iniciais do Firestore e Storage criadas.
- Arquivos restantes da galeria removidos do novo `lib/`.
- Credenciais Firebase da aula removidas.
- Checagem do VS Code nao encontrou erros nos arquivos Dart analisados.

Nao validado ainda:

- `flutter pub get`.
- `dart format`.
- `flutter analyze` executado pelo SDK.
- `flutter test`.
- Execucao em emulador/dispositivo.
- Integracao real com Firebase.
- Testes automatizados de modelo, providers e widgets.

## Bloqueio conhecido

No ambiente usado durante esta sessao, os comandos `flutter` e `dart` nao estavam disponiveis no `PATH`:

```text
flutter: command not found
```

A validacao executavel depende da instalacao do Flutter SDK ou da correcao do `PATH`.

## Proximo passo para retomar

1. Instalar/configurar Flutter SDK e Dart; executar `flutter doctor`.
2. Entrar na pasta `pueblo_bank`.
3. Criar ou selecionar um projeto Firebase exclusivo do Pueblo Bank.
4. Executar `flutterfire configure` para Android/iOS.
5. Habilitar Email/Password no Firebase Authentication.
6. Criar Firestore e Storage.
7. Publicar `firestore.rules` e `storage.rules`.
8. Executar:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter run
```

9. Corrigir os erros revelados pela analise real do Dart/Flutter.
10. Criar testes automatizados e validar isolamento usando dois usuarios Firebase.

## Pontos para revisar na proxima sessao

- Confirmar compatibilidade das versoes do `pubspec.yaml` com a versao instalada do Flutter.
- Verificar se o projeto deve usar `DefaultFirebaseOptions.currentPlatform` gerado pelo FlutterFire.
- Confirmar a configuracao iOS do bundle identifier.
- Revisar o upload de recibos durante edicao e a remocao de recibos antigos.
- Adicionar exclusao de transacao pela interface, se mantida no escopo.
- Melhorar tratamento de erros, acessibilidade e mensagens em portugues.
- Adicionar testes unitarios, de provider e de widget.
- Revisar indices compostos necessarios para as consultas Firestore com filtros de data e categoria.
- Verificar se a regra de seguranca deve validar tambem campos e tipos dos documentos.
