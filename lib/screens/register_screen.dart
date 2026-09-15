import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes.dart';
import '../utils/auth_validators.dart';

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
  void initState() {
    super.initState();
    // Evita mostrar um erro deixado por uma tentativa anterior em outra tela.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<AuthProvider>().clearError());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context
        .read<AuthProvider>()
        .register(_email.text, _password.text);
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, Routes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              LengthLimitingTextInputFormatter(emailMaxLength),
            ],
            decoration: const InputDecoration(labelText: 'E-mail'),
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha'),
            validator: validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmation,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmar senha'),
            validator: (value) =>
                validatePasswordConfirmation(value, _password.text),
          ),
          const SizedBox(height: 24),
          if (auth.error != null)
            Text(
              auth.error!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.error),
            ),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: auth.loading ? null : _submit,
              child: auth.loading
                  ? const CircularProgressIndicator()
                  : const Text('Cadastrar')),
        ]),
      ),
    );
  }
}
