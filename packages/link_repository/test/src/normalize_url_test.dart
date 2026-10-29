import 'package:flutter_test/flutter_test.dart';
import 'package:link_repository/link_repository.dart';

void main() {
  const ownHost = 'short-9119db.web.app';

  String normalize(String input) => normalizeUrl(input, ownHost: ownHost);

  Matcher throwsReason(InvalidUrlReason reason) => throwsA(
    isA<InvalidUrlException>().having(
      (exception) => exception.reason,
      'reason',
      reason,
    ),
  );

  group('normalizeUrl', () {
    group('accepts', () {
      test('an https URL unchanged', () {
        expect(
          normalize('https://example.com/a?b=c#d'),
          'https://example.com/a?b=c#d',
        );
      });

      test('an http URL', () {
        expect(normalize('http://example.com'), 'http://example.com');
      });

      test('a URL without a scheme by prepending https', () {
        expect(normalize('example.com'), 'https://example.com');
      });

      test('surrounding whitespace by trimming it', () {
        expect(normalize('  example.com/path \n'), 'https://example.com/path');
      });

      test('mixed case by lowercasing only scheme and host', () {
        expect(
          normalize('HTTPS://Example.COM/Path'),
          'https://example.com/Path',
        );
      });

      test('an explicit port', () {
        expect(
          normalize('https://example.com:8080/x'),
          'https://example.com:8080/x',
        );
      });

      test('an IDN host', () {
        expect(normalize('https://bücher.de'), 'https://b%C3%BCcher.de');
      });

      test('a URL of exactly $maxUrlLength characters', () {
        const prefix = 'https://example.com/';
        final url = prefix + 'a' * (maxUrlLength - prefix.length);

        expect(normalize(url), hasLength(maxUrlLength));
      });
    });

    group('rejects with ${InvalidUrlReason.empty}', () {
      test('an empty input', () {
        expect(() => normalize(''), throwsReason(InvalidUrlReason.empty));
      });

      test('a whitespace-only input', () {
        expect(() => normalize(' \t\n '), throwsReason(InvalidUrlReason.empty));
      });
    });

    group('rejects with ${InvalidUrlReason.unsupportedScheme}', () {
      for (final input in [
        'javascript:alert(1)',
        'data:text/html,hi',
        'mailto:a@b.com',
        'ftp://x.com',
        // Reads as the scheme `example.com`, so it's rejected before
        // `https://` would be prepended.
        'example.com:8080',
      ]) {
        test(input, () {
          expect(
            () => normalize(input),
            throwsReason(InvalidUrlReason.unsupportedScheme),
          );
        });
      }
    });

    group('rejects with ${InvalidUrlReason.malformed}', () {
      for (final input in [
        'https://foo',
        'https://a@b.com',
        'https://google.com@evil.com',
        'https://exa mple.com',
        'https://example.com/\u0000',
        'https://[::1',
        'https://',
      ]) {
        test(input, () {
          expect(
            () => normalize(input),
            throwsReason(InvalidUrlReason.malformed),
          );
        });
      }
    });

    group('rejects with ${InvalidUrlReason.tooLong}', () {
      test('a URL of ${maxUrlLength + 1} characters', () {
        const prefix = 'https://example.com/';
        final url = prefix + 'a' * (maxUrlLength + 1 - prefix.length);

        expect(() => normalize(url), throwsReason(InvalidUrlReason.tooLong));
      });
    });

    group('rejects with ${InvalidUrlReason.selfLink}', () {
      test('a URL on the own host', () {
        expect(
          () => normalize('https://$ownHost/abc1234'),
          throwsReason(InvalidUrlReason.selfLink),
        );
      });

      test('a URL on the own host in a different case', () {
        expect(
          () => normalize('SHORT-9119DB.web.app/abc1234'),
          throwsReason(InvalidUrlReason.selfLink),
        );
      });
    });
  });

  group(InvalidUrlException, () {
    test('toString includes the reason', () {
      expect(
        const InvalidUrlException(InvalidUrlReason.empty).toString(),
        'InvalidUrlException(InvalidUrlReason.empty)',
      );
    });
  });
}
