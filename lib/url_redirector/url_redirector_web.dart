// coverage:ignore-file
import 'package:short/url_redirector/url_redirector.dart';
import 'package:web/web.dart' as web;

/// Creates the [UrlRedirector] used in the browser.
UrlRedirector createUrlRedirector() => const WebUrlRedirector();

/// A [UrlRedirector] that calls `window.location.replace`.
class WebUrlRedirector implements UrlRedirector {
  const new();

  @override
  void redirect(String url) => web.window.location.replace(url);
}
