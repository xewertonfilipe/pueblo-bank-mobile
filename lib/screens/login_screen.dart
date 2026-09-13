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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().signIn(_email.text, _password.text);
    if (success && mounted) Navigator.pushReplacementNamed(context, Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)), validator: (value) => value == null || !value.contains('@') ? 'Informe um e-mail valido.' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)), validator: (value) => value == null || value.length < 6 ? 'Use pelo menos seis caracteres.' : null),
                const SizedBox(height: 24),
                if (auth.error != null) ...[Text(auth.error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 12)],
                FilledButton(onPressed: auth.loading ? null : _submit, child: auth.loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Entrar')),
                TextButton(onPressed: () => Navigator.pushNamed(context, Routes.register), child: const Text('Criar uma conta')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
