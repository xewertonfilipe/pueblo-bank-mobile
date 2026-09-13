import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().register(_email.text, _password.text);
    if (success && mounted) Navigator.pushReplacementNamed(context, Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail'), validator: (value) => value == null || !value.contains('@') ? 'Informe um e-mail valido.' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha'), validator: (value) => value == null || value.length < 6 ? 'Use pelo menos seis caracteres.' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _confirmation, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar senha'), validator: (value) => value != _password.text ? 'As senhas precisam ser iguais.' : null),
          const SizedBox(height: 24),
          if (auth.error != null) Text(auth.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(onPressed: auth.loading ? null : _submit, child: auth.loading ? const CircularProgressIndicator() : const Text('Cadastrar')),
        ]),
      ),
    );
  }
}
