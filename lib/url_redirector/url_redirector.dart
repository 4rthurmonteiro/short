import 'package:short/url_redirector/url_redirector_stub.dart'
    if (dart.library.js_interop) 'package:short/url_redirector/url_redirector_web.dart';

/// Sends the browser to another URL.
abstract interface class UrlRedirector {
  /// Returns the implementation for the current platform.
  factory() => createUrlRedirector();

  /// Replaces the current page with [url], so Back skips the current page.
  void redirect(String url);
}
