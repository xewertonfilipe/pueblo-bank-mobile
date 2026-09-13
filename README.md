# Pueblo Bank

Aplicativo Flutter mobile para gerenciamento de transacoes financeiras.

## Stack

- Flutter
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Provider
- fl_chart

## Configuracao local

1. Instale o Flutter SDK e valide com `flutter doctor`.
2. Instale a Firebase CLI e o FlutterFire CLI.
3. Crie um projeto Firebase separado do projeto.
4. Habilite Email/Password em Authentication, crie o Firestore e habilite o Storage.
5. Na pasta deste projeto, execute `flutterfire configure` e selecione Android/iOS.
6. Publique `firestore.rules` e `storage.rules` no Firebase.
7. Execute `flutter pub get` e depois `flutter run`.

O arquivo `google-services.json` nao e versionado neste scaffold. Gere a configuracao do proprio projeto Pueblo Bank com o FlutterFire CLI.

## Estrutura

- `lib/models`: modelos de dados
- `lib/services`: acesso ao Firebase
- `lib/providers`: estado global com Provider
- `lib/screens`: telas
- `lib/widgets`: componentes de UI e graficos

As transacoes ficam em `users/{uid}/transactions` e os recibos em `receipts/{uid}/{transactionId}/{fileName}`.

## Verificacao

Depois de configurar o SDK e o Firebase, execute:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
