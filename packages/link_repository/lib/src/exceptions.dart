/// Why a URL was rejected by [InvalidUrlException].
enum InvalidUrlReason {
  /// The input was empty or only whitespace.
  empty,

  /// The URL uses a scheme other than `http` or `https`.
  unsupportedScheme,

  /// The input isn't a well-formed web URL.
  malformed,

  /// The normalized URL is longer than 2048 characters.
  tooLong,

  /// The URL points at the shortener's own host.
  selfLink,
}

/// {@template invalid_url_exception}
/// Thrown when the input can't be shortened.
/// {@endtemplate}
class InvalidUrlException implements Exception {
  /// {@macro invalid_url_exception}
  const new(this.reason);

  /// Why the input was rejected.
  final InvalidUrlReason reason;

  @override
  String toString() => 'InvalidUrlException($reason)';
}

/// {@template link_creation_exception}
/// Thrown when a short link couldn't be stored.
/// {@endtemplate}
class LinkCreationException implements Exception {
  /// {@macro link_creation_exception}
  const new([this.error]);

  /// The underlying error, if any.
  final Object? error;

  @override
  String toString() => 'LinkCreationException($error)';
}

/// {@template link_resolution_exception}
/// Thrown when a short link couldn't be looked up.
/// {@endtemplate}
class LinkResolutionException implements Exception {
  /// {@macro link_resolution_exception}
  const new(this.error);

  /// The underlying error.
  final Object error;

  @override
  String toString() => 'LinkResolutionException($error)';
}
