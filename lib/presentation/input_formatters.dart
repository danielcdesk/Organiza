import 'package:flutter/services.dart';

/// The UI accepts at most one billion reais; persisted values remain cents.
const maxMoneyInputCents = 100000000000;

String formatMoneyInput(int cents) {
  final negative = cents < 0;
  final absolute = cents.abs();
  final whole = (absolute ~/ 100).toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${negative ? '-' : ''}R\$ $grouped,${(absolute % 100).toString().padLeft(2, '0')}';
}

/// Parses Brazilian real text without floating-point rounding.
int? parseMoneyInput(String raw, {bool allowNegative = false}) {
  var value = raw.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (value.isEmpty) return null;
  final negative = value.startsWith('-');
  if (negative && !allowNegative) return null;
  if (negative) value = value.substring(1);
  if (!RegExp(r'^\d[\d.]*(,\d{0,2})?$').hasMatch(value)) return null;
  final parts = value.split(',');
  final whole = int.tryParse(parts.first.replaceAll('.', ''));
  if (whole == null) return null;
  final fraction =
      parts.length == 2 ? int.tryParse(parts.last.padRight(2, '0')) : 0;
  if (fraction == null) return null;
  final cents = whole * 100 + fraction;
  if (cents > maxMoneyInputCents) return null;
  return negative ? -cents : cents;
}

class BrlCentsInputFormatter extends TextInputFormatter {
  BrlCentsInputFormatter({this.allowNegative = false});

  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (allowNegative && newValue.text.trim() == '-') {
      return const TextEditingValue(
        text: '-',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    if (digits.isEmpty) return const TextEditingValue();
    final negative = allowNegative && newValue.text.trimLeft().startsWith('-');

    var digitsBeforeCursor = _digitsBefore(
      newValue.text,
      newValue.selection.extentOffset,
    );
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final erasedSeparator = oldDigits == digits &&
        newValue.text.length < oldValue.text.length &&
        oldValue.selection.isCollapsed;
    if (erasedSeparator) {
      final oldCursor = oldValue.selection.extentOffset;
      final backspace = newValue.selection.extentOffset < oldCursor;
      final oldBefore = _digitsBefore(oldValue.text, oldCursor);
      final removeAt = backspace ? oldBefore - 1 : oldBefore;
      if (removeAt >= 0 && removeAt < digits.length) {
        digits = digits.replaceRange(removeAt, removeAt + 1, '');
        digitsBeforeCursor = backspace ? removeAt : oldBefore;
      }
    }
    if (digits.isEmpty) return const TextEditingValue();
    final cents = int.tryParse(digits);
    if (cents == null || cents > maxMoneyInputCents) return oldValue;
    final formatted = formatMoneyInput(negative ? -cents : cents);
    final typingAtEnd = oldValue.selection.isCollapsed &&
        (oldValue.text.isEmpty ||
            oldValue.selection.extentOffset == oldValue.text.length) &&
        newValue.selection.extentOffset == newValue.text.length;
    final cursor = typingAtEnd
        ? formatted.length
        : _offsetAfterDigits(formatted, digitsBeforeCursor);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

class PercentInputFormatter extends TextInputFormatter {
  PercentInputFormatter({this.allowNegative = false, this.max = 100});

  final bool allowNegative;
  final double max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll('%', '').replaceAll('.', ',').trim();
    if (raw.isEmpty) return const TextEditingValue();
    if (allowNegative && raw == '-') {
      return const TextEditingValue(
        text: '-',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    if (!RegExp(
            allowNegative ? r'^-?\d{1,4}(,\d{0,2})?$' : r'^\d{1,4}(,\d{0,2})?$')
        .hasMatch(raw)) {
      return oldValue;
    }
    final value = parsePercentInput(
      raw.endsWith(',') ? raw.substring(0, raw.length - 1) : raw,
      allowNegative: allowNegative,
      max: max,
    );
    if (value == null) return oldValue;
    final formatted = '$raw%';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newValue.selection.extentOffset.clamp(0, raw.length),
      ),
    );
  }
}

double? parsePercentInput(String raw,
    {bool allowNegative = false, double max = 100}) {
  final text = raw.trim().replaceAll('%', '').replaceAll('.', ',');
  if (!RegExp(
          allowNegative ? r'^-?\d{1,4}(,\d{1,2})?$' : r'^\d{1,4}(,\d{1,2})?$')
      .hasMatch(text)) {
    return null;
  }
  final value = double.tryParse(text.replaceAll(',', '.'));
  if (value == null || value > max || value < (allowNegative ? -100 : 0)) {
    return null;
  }
  return value;
}

int _digitsBefore(String text, int offset) {
  final safe = offset.clamp(0, text.length);
  return RegExp(r'\d').allMatches(text.substring(0, safe)).length;
}

int _offsetAfterDigits(String text, int count) {
  if (count <= 0) return text.indexOf(RegExp(r'\d'));
  var seen = 0;
  for (var i = 0; i < text.length; i++) {
    if (RegExp(r'\d').hasMatch(text[i])) {
      seen++;
      if (seen == count) return i + 1;
    }
  }
  return text.length;
}
