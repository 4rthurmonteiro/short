import 'package:link_repository/src/exceptions.dart';

/// The longest URL that can be stored.
const maxUrlLength = 2048;

final _forbiddenCharacters = RegExp(r'[\s\x00-\x1F\x7F]');
final _schemePrefix = RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*:');

/// Normalizes [input] into an absolute `http` or `https` URL.
///
/// Prepends `https://` when no scheme is given, and lowercases the scheme
/// and host. Throws an [InvalidUrlException] when the input can't be
/// shortened, including when it points at [ownHost].
String normalizeUrl(String input, {required String ownHost}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw const InvalidUrlException(InvalidUrlReason.empty);
  }
  if (_forbiddenCharacters.hasMatch(trimmed)) {
    throw const InvalidUrlException(InvalidUrlReason.malformed);
  }
  // Catches `javascript:`, `data:` and `mailto:`. This must run before
  // prepending a scheme, since `Uri` would read `example.com:8080` as having
  // the scheme `example.com`.
  if (_schemePrefix.hasMatch(trimmed) && !trimmed.contains('://')) {
    throw const InvalidUrlException(InvalidUrlReason.unsupportedScheme);
  }

  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) {
    throw const InvalidUrlException(InvalidUrlReason.malformed);
  }
  if (!uri.isScheme('http') && !uri.isScheme('https')) {
    throw const InvalidUrlException(InvalidUrlReason.unsupportedScheme);
  }
  if (!uri.host.contains('.') || uri.userInfo.isNotEmpty) {
    throw const InvalidUrlException(InvalidUrlReason.malformed);
  }
  if (uri.host == ownHost.toLowerCase()) {
    throw const InvalidUrlException(InvalidUrlReason.selfLink);
  }

  final url = uri.toString();
  if (url.length > maxUrlLength) {
    throw const InvalidUrlException(InvalidUrlReason.tooLong);
  }
  return url;
}
