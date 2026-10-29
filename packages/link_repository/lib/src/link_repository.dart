import 'dart:math';

import 'package:firestore_link_api/firestore_link_api.dart';
import 'package:link_repository/src/code.dart' as codes;
import 'package:link_repository/src/exceptions.dart';
import 'package:link_repository/src/normalize_url.dart';

/// {@template link_repository}
/// Shortens URLs into codes and resolves codes back into URLs.
/// {@endtemplate}
class LinkRepository {
  /// {@macro link_repository}
  new({required this._api, Random? random})
    : _random = random ?? Random.secure();

  final FirestoreLinkApi _api;
  final Random _random;

  /// How many codes to try before giving up on a collision.
  static const maxAttempts = 3;

  /// Whether [code] is a well-formed short link code.
  static bool isValidCode(String code) => codes.isValidCode(code);

  /// Normalizes and validates [input], then stores it under a new code.
  ///
  /// Returns the code. Throws an [InvalidUrlException] when the input can't
  /// be shortened, and a [LinkCreationException] when it can't be stored.
  Future<String> shorten(String input, {required String ownHost}) async {
    final url = normalizeUrl(input, ownHost: ownHost);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = codes.generateCode(_random);
      try {
        await _api.createLink(code: code, url: url);
        return code;
      } on LinkCodeTakenException {
        continue;
      } on LinkApiException catch (error) {
        throw LinkCreationException(error);
      }
    }
    throw const LinkCreationException();
  }

  /// Returns the URL stored for [code], or `null` if there is none or the
  /// code is malformed.
  ///
  /// Throws a [LinkResolutionException] when the lookup fails.
  Future<String?> resolve(String code) async {
    if (!isValidCode(code)) return null;

    final String? url;
    try {
      url = await _api.getUrl(code);
    } on LinkApiException catch (error) {
      throw LinkResolutionException(error);
    }
    if (url == null) return null;

    // Defense in depth: never hand back anything but a web URL.
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }
    return url;
  }
}
