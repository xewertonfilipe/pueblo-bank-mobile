import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _biometricAvailable = false;
  bool _initialized = false;
  bool _showPasswordForm = false;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _prepareLoginScreen();
  }

  Future<void> _prepareLoginScreen() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    await auth.ready;
    final lastEmail = await auth.getLastEmail();
    final canUseBiometric = await auth.canUseBiometric();
    if (!mounted) return;
    if (lastEmail != null) _email.text = lastEmail;
    setState(() {
      _biometricAvailable = canUseBiometric;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (success && !auth.biometricEnabled && _biometricAvailable) {
      await _askToEnableBiometric();
    }
    if (success && mounted) Navigator.pushReplacementNamed(context, Routes.dashboard);
  }

  Future<void> _askToEnableBiometric() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login com biometria'),
        content: const Text('Deseja ativar o login com biometria para os próximos acessos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await context.read<AuthProvider>().enableBiometric();
    }
  }

  Future<void> _unlockWithBiometric() async {
    setState(() => _unlocking = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.unlockWithBiometric();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, Routes.dashboard);
      return;
    }
    setState(() => _unlocking = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_unlocking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final showBiometricUnlock = auth.hasUnlockableSession && _biometricAvailable && !_showPasswordForm;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.account_balance, size: 64, color: Color(0xFF075985)),
                const SizedBox(height: 20),
                Text('Pueblo Bank', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Suas financas, em um so lugar.', textAlign: TextAlign.center),
                const SizedBox(height: 40),
                if (showBiometricUnlock) ...[
                  OutlinedButton.icon(
                    onPressed: _unlockWithBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Entrar com biometria'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _showPasswordForm = true),
                    child: const Text('Usar e-mail e senha'),
                  ),
                ] else ...[
                  TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)), validator: (value) => value == null || !value.contains('@') ? 'Informe um e-mail valido.' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)), validator: (value) => value == null || value.length < 6 ? 'Use pelo menos seis caracteres.' : null),
                  const SizedBox(height: 24),
                  if (auth.error != null) ...[Text(auth.error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 12)],
                  FilledButton(onPressed: auth.loading ? null : _submit, child: auth.loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Entrar')),
                  TextButton(onPressed: () => Navigator.pushNamed(context, Routes.register), child: const Text('Criar uma conta')),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
