import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/utility/text_logic.dart';

void main() {
  group('evaluateNumberString', () {
    test('simple integer', () {
      expect(evaluateNumberString('42'), equals(42));
    });
    test('simple float', () {
      expect(evaluateNumberString('3.14'), closeTo(3.14, 1e-10));
    });
    test('addition', () {
      expect(evaluateNumberString('1+2'), equals(3));
    });
    test('subtraction', () {
      expect(evaluateNumberString('5-2'), equals(3));
    });
    test('multiplication', () {
      expect(evaluateNumberString('4*2'), equals(8));
    });
    test('division', () {
      expect(evaluateNumberString('8/2'), equals(4));
    });
    test('mixed operations', () {
      expect(evaluateNumberString('2+3*4'), equals(14));
      expect(evaluateNumberString('2*3+4'), equals(10));
      expect(evaluateNumberString('2+6/3'), equals(4));
    });
    test('parentheses', () {
      expect(evaluateNumberString('(2+3)*4'), equals(20));
      expect(evaluateNumberString('2*(3+4)'), equals(14));
      expect(evaluateNumberString('10/(2+3)'), equals(2));
    });
    test('whitespace handling', () {
      expect(evaluateNumberString(' 1 + 2 '), equals(3));
      expect(evaluateNumberString('  4* ( 2 + 1 ) '), equals(12));
    });
    test('decimal edge cases', () {
      expect(evaluateNumberString('.5 + .5'), equals(1));
      expect(evaluateNumberString('1.'), equals(1));
      expect(evaluateNumberString('0.1+0.2'), closeTo(0.3, 1e-10));
    });
    test('complex expressions', () {
      expect(evaluateNumberString('((2+3)*4-5)/3'), equals(5));
      expect(evaluateNumberString('2+3*(4-1)*2'), equals(20));
      expect(evaluateNumberString('((.1+.2)+(.3+.4))*2'), equals(2));
      expect(evaluateNumberString('10/(2+3*2)'), closeTo(1.25, 1e-10));
    });
    test('invalid input throws', () {
      expect(() => evaluateNumberString('abc'), throwsA(isA<FormatException>()));
      expect(() => evaluateNumberString('1+'), throwsA(isA<FormatException>()));
      expect(() => evaluateNumberString('1/0'), throwsA(isA<UnsupportedError>()));
    });
  });
}
