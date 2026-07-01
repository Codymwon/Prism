import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:prism/features/editor/presentation/utils/editor_helpers.dart';

void main() {
  group('BracketsPairingFormatter Tests', () {
    test('disabled formatter does not pair', () {
      final formatter = BracketsPairingFormatter(enabled: false);
      const oldVal = TextEditingValue(
        text: 'hello ',
        selection: TextSelection.collapsed(offset: 6),
      );
      const newVal = TextEditingValue(
        text: 'hello (',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, equals('hello ('));
      expect(result.selection.baseOffset, equals(7));
    });

    test('auto-pairs brackets and quotes when enabled', () {
      final formatter = BracketsPairingFormatter(enabled: true);

      // ── Test (
      final result1 = formatter.formatEditUpdate(
        const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0)),
        const TextEditingValue(text: '(', selection: TextSelection.collapsed(offset: 1)),
      );
      expect(result1.text, equals('()'));
      expect(result1.selection.baseOffset, equals(1));

      // ── Test [
      final result2 = formatter.formatEditUpdate(
        const TextEditingValue(text: 'a', selection: TextSelection.collapsed(offset: 1)),
        const TextEditingValue(text: 'a[', selection: TextSelection.collapsed(offset: 2)),
      );
      expect(result2.text, equals('a[]'));
      expect(result2.selection.baseOffset, equals(2));

      // ── Test {
      final result3 = formatter.formatEditUpdate(
        const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0)),
        const TextEditingValue(text: '{', selection: TextSelection.collapsed(offset: 1)),
      );
      expect(result3.text, equals('{}'));
      expect(result3.selection.baseOffset, equals(1));

      // ── Test "
      final result4 = formatter.formatEditUpdate(
        const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0)),
        const TextEditingValue(text: '"', selection: TextSelection.collapsed(offset: 1)),
      );
      expect(result4.text, equals('""'));
      expect(result4.selection.baseOffset, equals(1));
    });

    test('skips/overtypes closing character', () {
      final formatter = BracketsPairingFormatter(enabled: true);

      const oldVal = TextEditingValue(
        text: '()',
        selection: TextSelection.collapsed(offset: 1),
      );
      const newVal = TextEditingValue(
        text: '())',
        selection: TextSelection.collapsed(offset: 2),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);
      // It should skip over the existing ')' instead of adding another
      expect(result.text, equals('()'));
      expect(result.selection.baseOffset, equals(2));
    });

    test('deletes matching closing character on backspacing opening character', () {
      final formatter = BracketsPairingFormatter(enabled: true);

      const oldVal = TextEditingValue(
        text: '()',
        selection: TextSelection.collapsed(offset: 1),
      );
      const newVal = TextEditingValue(
        text: ')',
        selection: TextSelection.collapsed(offset: 0),
      );

      final result = formatter.formatEditUpdate(oldVal, newVal);
      // It should delete the matching ')' as well, resulting in empty string
      expect(result.text, equals(''));
      expect(result.selection.baseOffset, equals(0));
    });
  });
}
