import 'package:flutter/services.dart';

final class BrlCurrencyInputFormatter extends TextInputFormatter {
  const BrlCurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatBrlCurrencyInput(newValue.text);
    final selectionOffset = _selectionOffset(newValue, formatted);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  int _selectionOffset(TextEditingValue value, String formatted) {
    final offset = value.selection.baseOffset.clamp(0, value.text.length);
    final prefix = value.text.substring(0, offset);
    final parsed = _parseInput(value.text);
    final prefixHasDecimalSeparator = _hasDecimalSeparatorBeforeCursor(
      value.text,
      prefix,
      parsed,
    );

    if (prefixHasDecimalSeparator) {
      final decimalOffset = formatted.indexOf(',');
      if (decimalOffset >= 0) {
        final prefixFractionDigits = _digitsAfterLastSeparator(prefix);
        return (decimalOffset + 1 + prefixFractionDigits).clamp(
          0,
          formatted.length,
        );
      }
    }

    final integerDigitsBeforeCursor = prefix
        .substring(
          0,
          _firstDecimalSeparator(prefix) ?? prefix.length,
        )
        .replaceAll(RegExp(r'\D'), '')
        .length;
    return _offsetAfterDigits(formatted, integerDigitsBeforeCursor);
  }

  bool _hasDecimalSeparatorBeforeCursor(
    String text,
    String prefix,
    _ParsedInput parsed,
  ) {
    final separator = _firstDecimalSeparator(text);
    return separator != null && prefix.length > separator && parsed.hasDecimal;
  }

  int _offsetAfterDigits(String text, int digitCount) {
    if (digitCount == 0) return 0;
    var digitsSeen = 0;
    for (var index = 0; index < text.length; index++) {
      if (_isDigit(text[index])) {
        digitsSeen++;
        if (digitsSeen == digitCount) return index + 1;
      }
    }
    return text.length;
  }

  int _digitsAfterLastSeparator(String text) {
    final separator = _firstDecimalSeparator(text);
    if (separator == null) return 0;
    return text.substring(separator + 1).replaceAll(RegExp(r'\D'), '').length;
  }
}

String formatBrlCurrencyInput(String input) {
  final parsed = _parseInput(input);
  if (parsed.integerDigits.isEmpty) {
    return parsed.hasDecimal ? ',' : '';
  }

  final integerPart = _groupIntegerDigits(parsed.integerDigits);
  if (!parsed.hasDecimal) return integerPart;
  return '$integerPart,${parsed.fractionDigits}';
}

String formatBrlCurrency(double value) {
  final fixedValue = value.toStringAsFixed(2);
  final isNegative = fixedValue.startsWith('-');
  final unsignedValue = isNegative ? fixedValue.substring(1) : fixedValue;
  final parts = unsignedValue.split('.');
  final integerPart = _groupIntegerDigits(parts.first);
  return '${isNegative ? '-' : ''}$integerPart,${parts.last}';
}

double? parseBrlCurrency(String? input) {
  if (input == null || input.trim().isEmpty) return null;
  final parsed = _parseInput(input);
  if (parsed.integerDigits.isEmpty || parsed.hasInvalidCharacters) return null;

  final normalized = '${parsed.integerDigits}.${parsed.fractionDigits}';
  return double.tryParse(normalized);
}

String _groupIntegerDigits(String digits) {
  final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final groups = <String>[];
  for (var end = normalized.length; end > 0; end -= 3) {
    final start = (end - 3).clamp(0, end);
    groups.insert(0, normalized.substring(start, end));
  }
  return groups.isEmpty ? '0' : groups.join('.');
}

_ParsedInput _parseInput(String input) {
  final hasInvalidCharacters = RegExp(r'[^0-9.,]').hasMatch(input);
  final separators = [
    for (var index = 0; index < input.length; index++)
      if (input[index] == ',' || input[index] == '.') index,
  ];
  if (separators.isEmpty) {
    return _ParsedInput(
      integerDigits: input.replaceAll(RegExp(r'\D'), ''),
      fractionDigits: '',
      hasDecimal: false,
      hasInvalidCharacters: hasInvalidCharacters,
    );
  }

  final lastSeparator = separators.last;
  final separator = input[lastSeparator];
  final digitsAfterSeparator =
      input.substring(lastSeparator + 1).replaceAll(RegExp(r'\D'), '');
  final shouldUseDecimal = separator == ',' ||
      lastSeparator == input.length - 1 ||
      digitsAfterSeparator.length <= 2;

  if (!shouldUseDecimal) {
    return _ParsedInput(
      integerDigits: input.replaceAll(RegExp(r'\D'), ''),
      fractionDigits: '',
      hasDecimal: false,
      hasInvalidCharacters: hasInvalidCharacters,
    );
  }

  final integerDigits =
      input.substring(0, lastSeparator).replaceAll(RegExp(r'\D'), '');
  return _ParsedInput(
    integerDigits: integerDigits,
    fractionDigits: digitsAfterSeparator.substring(
        0, digitsAfterSeparator.length.clamp(0, 2)),
    hasDecimal: true,
    hasInvalidCharacters: hasInvalidCharacters,
  );
}

int? _firstDecimalSeparator(String input) {
  final parsed = _parseInput(input);
  if (!parsed.hasDecimal) return null;
  final comma = input.lastIndexOf(',');
  final dot = input.lastIndexOf('.');
  if (comma < 0) return dot;
  if (dot < 0) return comma;
  return comma > dot ? comma : dot;
}

bool _isDigit(String character) => RegExp(r'\d').hasMatch(character);

class _ParsedInput {
  const _ParsedInput({
    required this.integerDigits,
    required this.fractionDigits,
    required this.hasDecimal,
    required this.hasInvalidCharacters,
  });

  final String integerDigits;
  final String fractionDigits;
  final bool hasDecimal;
  final bool hasInvalidCharacters;
}
