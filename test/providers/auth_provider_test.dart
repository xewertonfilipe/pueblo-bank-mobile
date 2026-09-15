import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/providers/auth_provider.dart';
import 'package:pueblo_bank/services/auth_service.dart';
import 'package:pueblo_bank/services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockUser extends Fake implements User {}

class _MockUserCredential extends Fake implements UserCredential {}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.initialUser});

  final User? initialUser;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => initialUser;

  @override
  Future<UserCredential> signIn(String email, String password) async {
    return _MockUserCredential();
  }
}

class _FakeBiometricService extends BiometricService {
  _FakeBiometricService({required this.authenticationResult});

  final bool authenticationResult;

  @override
  Future<bool> authenticate(String reason) async => authenticationResult;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('bloqueia uma sessão com biometria ativada', () async {
    final provider = AuthProvider(
      service: _FakeAuthService(initialUser: _MockUser()),
      biometricService: _FakeBiometricService(authenticationResult: true),
    );

    await provider.enableBiometric();
    await provider.lock();

    expect(provider.isLocked, isTrue);
    expect(provider.hasUnlockableSession, isTrue);
    provider.dispose();
  });

  test('não bloqueia uma sessão sem biometria ativada', () async {
    final provider = AuthProvider(
      service: _FakeAuthService(initialUser: _MockUser()),
      biometricService: _FakeBiometricService(authenticationResult: true),
    );

    await provider.lock();

    expect(provider.isLocked, isFalse);
    expect(provider.hasUnlockableSession, isFalse);
    provider.dispose();
  });

  test('falha biométrica mantém a sessão bloqueada', () async {
    final provider = AuthProvider(
      service: _FakeAuthService(initialUser: _MockUser()),
      biometricService: _FakeBiometricService(authenticationResult: false),
    );

    await provider.enableBiometric();
    await provider.lock();
    final unlocked = await provider.unlockWithBiometric();

    expect(unlocked, isFalse);
    expect(provider.isLocked, isTrue);
    provider.dispose();
  });

  test('autenticação biométrica aprovada desbloqueia a sessão', () async {
    final provider = AuthProvider(
      service: _FakeAuthService(initialUser: _MockUser()),
      biometricService: _FakeBiometricService(authenticationResult: true),
    );

    await provider.enableBiometric();
    await provider.lock();
    final unlocked = await provider.unlockWithBiometric();

    expect(unlocked, isTrue);
    expect(provider.isLocked, isFalse);
    provider.dispose();
  });

  test('login por senha desbloqueia a sessão', () async {
    final provider = AuthProvider(
      service: _FakeAuthService(initialUser: _MockUser()),
      biometricService: _FakeBiometricService(authenticationResult: true),
    );

    await provider.enableBiometric();
    await provider.lock();
    final signedIn = await provider.signIn('user@teste.com', '123456');

    expect(signedIn, isTrue);
    expect(provider.isLocked, isFalse);
    provider.dispose();
  });
}
