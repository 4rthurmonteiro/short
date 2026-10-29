// Not required for test files
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:link_repository/link_repository.dart';

void main() {
  group('LinkRepository', () {
    test('can be instantiated', () {
      expect(LinkRepository(), isNotNull);
    });
  });
}
