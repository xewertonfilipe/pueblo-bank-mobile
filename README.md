# Pueblo Bank

![CI](https://github.com/OWNER/pueblo-bank-mobile/actions/workflows/ci.yml/badge.svg)

Aplicativo Flutter mobile para gerenciamento de transações financeiras, com autenticação,
dashboard com gráficos, listagem paginada de transações e upload de recibos vinculados ao
usuário e à transação.

## Requisitos atendidos

- **Login**: e-mail/senha via Firebase Authentication ([lib/screens/login_screen.dart](lib/screens/login_screen.dart)).
- **Dashboard**: saldo, depósitos, saques e gráficos (evolução financeira e distribuição por
  categoria) usando `fl_chart` ([lib/screens/dashboard_screen.dart](lib/screens/dashboard_screen.dart)).
- **Listagem de transações**: filtros por data e categoria (depósito/saque), paginação por
  cursor do Cloud Firestore e carregamento sob demanda ao tentar rolar a lista
  ([lib/screens/transactions_screen.dart](lib/screens/transactions_screen.dart)).
- **Adicionar/editar transação**: validação de valor e categoria, upload de recibo salvo no
  Firebase Storage vinculado ao usuário autenticado e à transação
  ([lib/screens/transaction_form_screen.dart](lib/screens/transaction_form_screen.dart)).
- **Estado global**: gerenciado com Provider (`AuthProvider`, `TransactionProvider`).
- **Segurança**: regras do Firestore e do Storage restringem leitura/escrita ao próprio
  usuário autenticado (`firestore.rules`, `storage.rules`).

## Stack

- Flutter (Mobile)
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase App Check
- Provider
- fl_chart
- image_picker
- another_flushbar

## Dependências principais (pubspec.yaml)

| Pacote               | Uso                                            |
| -------------------- | ---------------------------------------------- |
| `firebase_core`      | Inicialização do Firebase                      |
| `firebase_auth`      | Login e cadastro com e-mail/senha              |
| `cloud_firestore`    | Armazenamento e consulta das transações        |
| `firebase_storage`   | Upload dos recibos das transações              |
| `firebase_app_check` | Proteção contra abuso nas chamadas ao Firebase |
| `provider`           | Gerenciamento de estado global                 |
| `image_picker`       | Seleção do recibo (imagem) na galeria          |
| `fl_chart`           | Gráficos do dashboard                          |
| `another_flushbar`   | Notificações visuais de sucesso/erro           |

## Configuração do Firebase

1. Instale o Flutter SDK e valide com `flutter doctor`.
2. Instale a Firebase CLI e o FlutterFire CLI.
3. Crie um projeto no [Firebase Console](https://console.firebase.google.com).
4. Ative **Authentication** → método Email/Password.
5. Crie o **Cloud Firestore** (modo produção) e publique as regras de [firestore.rules](firestore.rules).
6. Ative o **Firebase Storage** e publique as regras de [storage.rules](storage.rules).
7. Na pasta deste projeto, execute `flutterfire configure` e selecione Android/iOS.
   Isso gera `lib/firebase_options.dart` e o `google-services.json` (Android).

### Configurar Firebase App Check

O app usa Firebase App Check para proteger as chamadas ao Storage e ao Firestore.

1. No Firebase Console, abra **Project settings → Your apps** e confirme o app Android
   (`applicationId` = `pueblo.bank`).
2. Gere o fingerprint SHA-256 de debug:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copie o valor `SHA-256` da seção `debug` e cadastre em **Project settings → Your apps**.
3. No Firebase Console, abra **App Check** e selecione o app Android.
4. Escolha **Play Integrity** como provider de produção.
5. Rode o app em modo debug (`flutter run`). No Logcat, procure uma mensagem como:
   ```text
   Failed to exchange debug token (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
   ```
6. Copie esse token e registre em **App Check → Manage debug tokens → Add**.
7. Reinicie o app. O aviso de token deve desaparecer e os uploads devem funcionar sem
   `App attestation failed`.

Em produção, mantenha `AndroidProvider.playIntegrity` na inicialização do App Check em
[lib/main.dart](lib/main.dart) e ative o enforcement apenas depois de validar o fluxo completo.

## Rodando localmente

1. Execute `flutter pub get`.
2. Conecte um dispositivo Android físico com depuração USB habilitada, ou inicie um emulador.
3. Confirme o dispositivo com `flutter devices`.
4. Execute `flutter run`.
5. Durante o desenvolvimento:
   - `r` no terminal → hot reload (mudanças de UI/lógica simples).
   - `R` no terminal → hot restart (necessário após mudanças estruturais, como em
     `initState` ou providers).

O arquivo `google-services.json` não é versionado neste projeto. Gere a configuração do próprio projeto Firebase com o FlutterFire CLI (passo 7 da seção anterior).

## Estrutura

- `lib/models`: modelos de dados (ex.: `TransactionModel`)
- `lib/services`: acesso ao Firebase (Auth, Firestore, Storage)
- `lib/providers`: estado global com Provider (`AuthProvider`, `TransactionProvider`)
- `lib/screens`: telas (login, cadastro, dashboard, transações, formulário)
- `lib/widgets`: componentes de UI e gráficos do dashboard

As transações ficam em `users/{uid}/transactions` e os recibos em `receipts/{uid}/{transactionId}/{fileName}`, onde `{transactionId}` é o mesmo ID usado no documento Firestore e no caminho do Storage — garantindo que o recibo sempre fique vinculado à transação e ao usuário autenticado.

## Solução de problemas

- **`No AppCheckProvider installed` / `Error getting App Check token`**: o Firebase App Check
  não está configurado. Siga a seção "Configurar Firebase App Check" acima.
- **`Failed to exchange debug token` / `App attestation failed`**: o token de debug do
  dispositivo não foi registrado no Firebase Console. Copie o token exibido no Logcat e
  registre em **App Check → Manage debug tokens**.
- **`No document to update` ao editar uma transação com recibo**: já corrigido — o app usa
  o mesmo ID de transação tanto no Firestore quanto no caminho do Storage.

## Verificação

Depois de configurar o SDK e o Firebase, execute:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## 🧪 Testes

O projeto usa `flutter_test` com [mocktail](https://pub.dev/packages/mocktail) para mock de
dependências (serviços do Firebase) sem code-generation.

```bash
# Testes unitários e de widgets
flutter test

# Com relatório de cobertura
flutter test --coverage
```

## 📱 Testes E2E com Maestro

Os fluxos ponta-a-ponta ficam em [.maestro/](.maestro/), cobrindo login, cadastro,
adicionar/editar transação, filtros e logout.

1. Instale o [Maestro CLI](https://maestro.mobile.dev/):
   ```bash
   curl -Ls "https://get.maestro.mobile.dev" | bash
   ```
2. Gere e instale o APK debug num emulador/dispositivo:
   ```bash
   flutter build apk --debug
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```
3. Rode um fluxo específico ou todos:
   ```bash
   maestro test .maestro/01_login_success.yaml
   maestro test .maestro/
   ```

## ⚙️ CI/CD

O workflow em [.github/workflows/ci.yml](.github/workflows/ci.yml) roda em cada `push`/`pull_request`:
análise estática, testes unitários/widgets com cobertura, build do APK debug e os fluxos
E2E do Maestro num emulador Android.
