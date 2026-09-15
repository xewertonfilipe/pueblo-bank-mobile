import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service, BiometricService? biometricService})
      : _service = service ?? AuthService(),
        _biometricService = biometricService ?? BiometricService() {
    _user = _service.currentUser;
    _subscription = _service.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
    _readyFuture = _loadPersistedFlags();
  }

  final AuthService _service;
  final BiometricService _biometricService;
  StreamSubscription<User?>? _subscription;
  late final Future<void> _readyFuture;
  User? _user;
  bool _loading = false;
  String? _error;
  bool _biometricEnabled = false;
  bool _locked = false;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  Future<void> get ready => _readyFuture;
  bool get biometricEnabled => _biometricEnabled;
  bool get isLocked => _locked;
  bool get hasUnlockableSession =>
      _user != null && _locked && _biometricEnabled;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _loadPersistedFlags() async {
    _biometricEnabled = await _service.getBiometricEnabled();
    _locked = _biometricEnabled;
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _service.signIn(email, password));
  Future<bool> register(String email, String password) =>
      _run(() => _service.register(email, password));

  Future<String?> getLastEmail() => _service.getLastEmail();

  Future<bool> canUseBiometric() => _biometricService.canUseBiometric();

  Future<bool> unlockWithBiometric() async {
    if (_user == null) return false;
    final success = await _biometricService
        .authenticate('Confirme sua identidade para entrar no Pueblo Bank');
    if (success) {
      _locked = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> enableBiometric() async {
    _biometricEnabled = true;
    _locked = false;
    await _service.setBiometricEnabled(true);
    notifyListeners();
  }

  Future<void> disableBiometric() async {
    _biometricEnabled = false;
    _locked = false;
    await _service.setBiometricEnabled(false);
    await signOut();
  }

  Future<void> lock() async {
    if (!_biometricEnabled || _locked) return;
    _locked = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    notifyListeners();
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _locked = false;
      return true;
    } on FirebaseAuthException catch (exception) {
      _error = _messageFor(exception.code);
      return false;
    } catch (_) {
      _error = 'Não foi possível concluir a operação.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Use uma senha com pelo menos seis caracteres.';
      default:
        return 'Não foi possível autenticar. Tente novamente.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
