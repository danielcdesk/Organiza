import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiza/presentation/input_formatters.dart';

void main() {
  TextEditingValue type(BrlCentsInputFormatter formatter, String old,
          String next, int cursor) =>
      formatter.formatEditUpdate(
        TextEditingValue(
          text: old,
          selection: TextSelection.collapsed(offset: old.length),
        ),
        TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: cursor),
        ),
      );

  test('digit-shift BRL from one cent through thousands', () {
    final formatter = BrlCentsInputFormatter();
    var value = const TextEditingValue();
    for (final (digit, expected) in [
      ('1', 'R\$ 0,01'),
      ('2', 'R\$ 0,12'),
      ('3', 'R\$ 1,23'),
      ('4', 'R\$ 12,34'),
      ('5', 'R\$ 123,45'),
      ('6', 'R\$ 1.234,56'),
    ]) {
      value = formatter.formatEditUpdate(
        value,
        TextEditingValue(
          text: '${value.text}$digit',
          selection: TextSelection.collapsed(offset: value.text.length + 1),
        ),
      );
      expect(value.text, expected);
    }
    expect(parseMoneyInput(value.text), 123456);
  });

  test('caret remains at the end during natural digit-by-digit typing', () {
    final formatter = BrlCentsInputFormatter();
    var value = const TextEditingValue(
      selection: TextSelection.collapsed(offset: 0),
    );
    for (final (digit, expected) in [
      ('1', 'R\$ 0,01'),
      ('2', 'R\$ 0,12'),
      ('3', 'R\$ 1,23'),
    ]) {
      final next = value.text.replaceRange(
          value.selection.extentOffset, value.selection.extentOffset, digit);
      value = formatter.formatEditUpdate(
        value,
        TextEditingValue(
          text: next,
          selection:
              TextSelection.collapsed(offset: value.selection.extentOffset + 1),
        ),
      );
      expect(value.text, expected);
      expect(value.selection.extentOffset, value.text.length);
    }
  });

  test('paste formatted BRL, leading zeros and clear', () {
    final formatter = BrlCentsInputFormatter();
    expect(type(formatter, '', 'R\$ 001.234,56', 13).text, 'R\$ 1.234,56');
    expect(type(formatter, '', '00000025000', 11).text, 'R\$ 250,00');
    expect(type(formatter, 'R\$ 25,00', '', 0).text, isEmpty);
  });

  test('backspace and delete on separators remove an adjacent digit', () {
    final formatter = BrlCentsInputFormatter();
    final backspace = formatter.formatEditUpdate(
      const TextEditingValue(
        text: 'R\$ 12,34',
        selection: TextSelection.collapsed(offset: 6),
      ),
      const TextEditingValue(
        text: 'R\$ 1234',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(backspace.text, 'R\$ 1,34');
    final delete = formatter.formatEditUpdate(
      const TextEditingValue(
        text: 'R\$ 12,34',
        selection: TextSelection.collapsed(offset: 5),
      ),
      const TextEditingValue(
        text: 'R\$ 1234',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(delete.text, 'R\$ 1,24');
  });

  test('editing an existing value preserves cent precision', () {
    final formatter = BrlCentsInputFormatter();
    expect(formatMoneyInput(12345), 'R\$ 123,45');
    final edited = formatter.formatEditUpdate(
      const TextEditingValue(
        text: 'R\$ 123,45',
        selection: TextSelection(baseOffset: 4, extentOffset: 6),
      ),
      const TextEditingValue(
        text: 'R\$ 93,45',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(edited.text, 'R\$ 93,45');
    expect(parseMoneyInput(edited.text), 9345);
  });

  test('percentages do not shift by two decimal places', () {
    final formatter = PercentInputFormatter();
    expect(
        formatter
            .formatEditUpdate(
              const TextEditingValue(),
              const TextEditingValue(
                text: '10',
                selection: TextSelection.collapsed(offset: 2),
              ),
            )
            .text,
        '10%');
    expect(parsePercentInput('2,5%'), 2.5);
  });

  test('signed account balance keeps a negative value while editing', () {
    final formatter = BrlCentsInputFormatter(allowNegative: true);
    final value = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '-1234',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(value.text, '-R\$ 12,34');
    expect(parseMoneyInput(value.text, allowNegative: true), -1234);
  });

  test('investment return accepts a signed percentage', () {
    final formatter = PercentInputFormatter(allowNegative: true);
    final value = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '-2,5',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    expect(value.text, '-2,5%');
    expect(parsePercentInput(value.text, allowNegative: true), -2.5);
  });

  test('investment return permits up to 1000 percent', () {
    final formatter = PercentInputFormatter(allowNegative: true, max: 1000);
    final value = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '250,5',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(value.text, '250,5%');
    expect(
        parsePercentInput(value.text, allowNegative: true, max: 1000), 250.5);
  });

  test('decimal point from numeric keyboards displays a Brazilian comma', () {
    final value = PercentInputFormatter().formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '2.5',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    expect(value.text, '2,5%');
  });

  test('percentage lets the user type comma before fractional digits', () {
    final formatter = PercentInputFormatter();
    final value = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '2%',
        selection: TextSelection.collapsed(offset: 1),
      ),
      const TextEditingValue(
        text: '2,%',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(value.text, '2,%');
  });

  test('signed percentage lets minus be entered before the number', () {
    final value = PercentInputFormatter(allowNegative: true).formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '-',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    expect(value.text, '-');
  });

  test('signed money lets minus be entered before the number', () {
    final value = BrlCentsInputFormatter(allowNegative: true).formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '-',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    expect(value.text, '-');
  });
}
