import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _subscription = _service.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthService _service;
  StreamSubscription<User?>? _subscription;
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> signIn(String email, String password) => _run(() => _service.signIn(email, password));
  Future<bool> register(String email, String password) => _run(() => _service.register(email, password));

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
