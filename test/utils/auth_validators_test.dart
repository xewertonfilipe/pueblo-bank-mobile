import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/utils/auth_validators.dart';

void main() {
  group('validateEmail', () {
    test('aceita e-mail válido dentro do limite', () {
      expect(validateEmail('user@teste.com'), isNull);
    });

    test('rejeita e-mails vazios ou com estrutura inválida', () {
      expect(validateEmail(null), isNotNull);
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('usuario'), isNotNull);
      expect(validateEmail('usuario@'), isNotNull);
      expect(validateEmail('usuario@dominio'), isNotNull);
      expect(validateEmail('usuario@.com'), isNotNull);
      expect(validateEmail('usuario @teste.com'), isNotNull);
      expect(validateEmail('usuario@@teste.com'), isNotNull);
    });

    test('rejeita e-mail acima de 254 caracteres', () {
      final email = '${'a' * 245}@teste.com';

      expect(email.length, greaterThan(emailMaxLength));
      expect(validateEmail(email), isNotNull);
    });
  });

  group('validatePassword', () {
    test('exige pelo menos seis caracteres', () {
      expect(validatePassword(null), isNotNull);
      expect(validatePassword('12345'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test('exige confirmação igual à senha', () {
      expect(validatePasswordConfirmation('123456', '123456'), isNull);
      expect(validatePasswordConfirmation('654321', '123456'), isNotNull);
    });
  });
}
