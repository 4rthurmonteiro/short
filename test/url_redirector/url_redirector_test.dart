import 'package:flutter_test/flutter_test.dart';
import 'package:short/url_redirector/url_redirector.dart';
import 'package:short/url_redirector/url_redirector_stub.dart';

void main() {
  group(UrlRedirector, () {
    test('uses $UnsupportedUrlRedirector outside the browser', () {
      expect(UrlRedirector(), isA<UnsupportedUrlRedirector>());
    });
  });

  group(UnsupportedUrlRedirector, () {
    test('redirect throws $UnsupportedError', () {
      expect(
        () => const UnsupportedUrlRedirector().redirect('https://example.com'),
        throwsUnsupportedError,
      );
    });
  });
}
