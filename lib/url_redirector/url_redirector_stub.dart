import 'package:short/url_redirector/url_redirector.dart';

/// Creates the [UrlRedirector] used outside the browser.
UrlRedirector createUrlRedirector() => const UnsupportedUrlRedirector();

/// A [UrlRedirector] for platforms without a browser window.
class UnsupportedUrlRedirector implements UrlRedirector {
  const new();

  @override
  void redirect(String url) {
    throw UnsupportedError('Redirecting is only supported on the web.');
  }
}
