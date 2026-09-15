import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pueblo_bank/utils/brl_currency.dart';

void main() {
  const formatter = BrlCurrencyInputFormatter();

  TextEditingValue format(String text, {int? selection}) {
    final value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selection ?? text.length,
      ),
    );
    return formatter.formatEditUpdate(const TextEditingValue(), value);
  }

  group('BrlCurrencyInputFormatter', () {
    test('agrupa milhares e preserva duas casas decimais', () {
      expect(format('1234,56').text, '1.234,56');
      expect(format('1234567,8').text, '1.234.567,8');
    });

    test('normaliza ponto decimal e valor colado', () {
      expect(format('1234.56').text, '1.234,56');
      expect(format('1.234,56').text, '1.234,56');
    });

    test('limita a duas casas e remove caracteres inválidos', () {
      expect(format('12a34,567').text, '1.234,56');
      expect(format('1234,').text, '1.234,');
    });

    test('mantém o cursor após a casa decimal', () {
      final value = format('1234,56');
      expect(value.selection.baseOffset, value.text.length);

      final decimalSeparator = format('1234,');
      expect(decimalSeparator.text, '1.234,');
      expect(
          decimalSeparator.selection.baseOffset, decimalSeparator.text.length);
    });
  });

  group('parseBrlCurrency', () {
    test('converte formato brasileiro para double', () {
      expect(parseBrlCurrency('1.234,56'), 1234.56);
      expect(parseBrlCurrency('1234.56'), 1234.56);
    });

    test('rejeita entradas vazias, inválidas e sem valor', () {
      expect(parseBrlCurrency(null), isNull);
      expect(parseBrlCurrency(''), isNull);
      expect(parseBrlCurrency('abc'), isNull);
      expect(parseBrlCurrency('1.234,56x'), isNull);
      expect(parseBrlCurrency('-1'), isNull);
      expect(parseBrlCurrency('0'), 0);
    });
  });

  test('formatBrlCurrency prepara o valor inicial de edição', () {
    expect(formatBrlCurrency(1234.56), '1.234,56');
    expect(formatBrlCurrency(-100.5), '-100,50');
  });
}
