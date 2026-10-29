import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:link_repository/link_repository.dart';

void main() {
  group('generateCode', () {
    test('returns $codeLength base62 characters', () {
      final random = Random(42);
      for (var i = 0; i < 100; i++) {
        final code = generateCode(random);
        expect(code, matches(RegExp(r'^[0-9A-Za-z]{7}$')));
      }
    });

    test('is deterministic for a seeded Random', () {
      expect(generateCode(Random(1)), equals(generateCode(Random(1))));
    });

    test('differs between calls', () {
      final random = Random(1);
      expect(generateCode(random), isNot(equals(generateCode(random))));
    });
  });

  group('isValidCode', () {
    test('accepts 7 base62 characters', () {
      expect(LinkRepository.isValidCode('aB3dE5g'), isTrue);
    });

    for (final code in [
      '',
      'aB3dE5',
      'aB3dE5gh',
      'aB3-E5g',
      'aB3dE5g/',
      'äB3dE5g',
    ]) {
      test('rejects "$code"', () {
        expect(LinkRepository.isValidCode(code), isFalse);
      });
    }
  });
}
