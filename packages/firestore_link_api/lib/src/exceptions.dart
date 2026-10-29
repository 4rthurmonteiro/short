/// {@template link_api_exception}
/// Thrown when a Firestore request fails or doesn't finish in time.
/// {@endtemplate}
class LinkApiException implements Exception {
  /// {@macro link_api_exception}
  const new(this.error);

  /// The underlying error.
  final Object error;

  @override
  String toString() => 'LinkApiException($error)';
}

/// {@template link_code_taken_exception}
/// Thrown when Firestore rejects a write because the code is already in use.
///
/// The security rules only allow creating documents that don't exist yet,
/// so overwriting an existing code comes back as `permission-denied`.
/// {@endtemplate}
class LinkCodeTakenException implements Exception {
  /// {@macro link_code_taken_exception}
  const new(this.code);

  /// The code that was rejected.
  final String code;

  @override
  String toString() => 'LinkCodeTakenException($code)';
}
