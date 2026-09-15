const emailMaxLength = 254;

String? validateEmail(String? value) {
  if (value == null || value.isEmpty || value.length > emailMaxLength) {
    return 'Informe um e-mail valido.';
  }

  final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  return emailPattern.hasMatch(value) ? null : 'Informe um e-mail valido.';
}

String? validatePassword(String? value) {
  return value == null || value.length < 6
      ? 'Use pelo menos seis caracteres.'
      : null;
}

String? validatePasswordConfirmation(String? value, String password) {
  return value != password ? 'As senhas precisam ser iguais.' : null;
}
