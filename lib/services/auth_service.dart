import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _customAuth = auth;

  static const _lastEmailKey = 'last_signed_in_email';
  static const _biometricEnabledKey = 'biometric_enabled';

  final FirebaseAuth? _customAuth;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _saveLastEmail(email.trim());
    return credential;
  }

  Future<UserCredential> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _saveLastEmail(email.trim());
    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> _saveLastEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastEmailKey, email);
  }

  Future<String?> getLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastEmailKey);
  }

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, value);
  }
}


