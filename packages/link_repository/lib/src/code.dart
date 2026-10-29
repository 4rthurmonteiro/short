import 'dart:math';

const _alphabet =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

/// The number of characters in a short link code.
const codeLength = 7;

final _codePattern = RegExp('^[0-9A-Za-z]{$codeLength}\$');

/// Generates a random base62 code of [codeLength] characters.
String generateCode(Random random) => String.fromCharCodes(
  List.generate(
    codeLength,
    (_) => _alphabet.codeUnitAt(random.nextInt(_alphabet.length)),
  ),
);

/// Whether [code] is a well-formed short link code.
bool isValidCode(String code) => _codePattern.hasMatch(code);
