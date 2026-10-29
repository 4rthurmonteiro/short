/// Repository that shortens and resolves short links.
library;

export 'src/code.dart' show codeLength, generateCode;
export 'src/exceptions.dart';
export 'src/link_repository.dart';
export 'src/normalize_url.dart' show maxUrlLength, normalizeUrl;
