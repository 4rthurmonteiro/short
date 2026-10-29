import 'dart:math';

import 'package:firestore_link_api/firestore_link_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_repository/link_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestoreLinkApi extends Mock implements FirestoreLinkApi;

void main() {
  const ownHost = 'short-9119db.web.app';
  const url = 'https://example.com/path';
  const code = 'aB3dE5g';

  group(LinkRepository, () {
    late FirestoreLinkApi api;
    late LinkRepository repository;

    setUp(() {
      api = _MockFirestoreLinkApi();
      repository = LinkRepository(api: api, random: Random(7));
    });

    List<String> expectedCodes(int count) {
      final random = Random(7);
      return List.generate(count, (_) => generateCode(random));
    }

    test('can be created with the default Random', () {
      expect(LinkRepository(api: api), isNotNull);
    });

    group('shorten', () {
      test('stores the normalized URL under a new code', () async {
        when(
          () => api.createLink(
            code: any(named: 'code'),
            url: any(named: 'url'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.shorten(
          'Example.com/path',
          ownHost: ownHost,
        );

        expect(result, equals(expectedCodes(1).single));
        verify(
          () => api.createLink(code: result, url: 'https://example.com/path'),
        ).called(1);
      });

      test('throws $InvalidUrlException without writing', () async {
        await expectLater(
          repository.shorten('javascript:alert(1)', ownHost: ownHost),
          throwsA(isA<InvalidUrlException>()),
        );
        verifyZeroInteractions(api);
      });

      test('retries with a new code when the code is taken', () async {
        final codes = expectedCodes(3);
        when(() => api.createLink(code: codes[0], url: url))
            .thenThrow(LinkCodeTakenException(codes[0]));
        when(() => api.createLink(code: codes[1], url: url))
            .thenThrow(LinkCodeTakenException(codes[1]));
        when(() => api.createLink(code: codes[2], url: url))
            .thenAnswer((_) async {});

        expect(
          await repository.shorten(url, ownHost: ownHost),
          equals(codes[2]),
        );
        verify(
          () => api.createLink(
            code: any(named: 'code'),
            url: url,
          ),
        ).called(3);
      });

      test('throws $LinkCreationException after '
          '${LinkRepository.maxAttempts} taken codes', () async {
        when(
          () => api.createLink(
            code: any(named: 'code'),
            url: url,
          ),
        ).thenThrow(const LinkCodeTakenException(code));

        await expectLater(
          repository.shorten(url, ownHost: ownHost),
          throwsA(isA<LinkCreationException>()),
        );
        verify(
          () => api.createLink(
            code: any(named: 'code'),
            url: url,
          ),
        ).called(LinkRepository.maxAttempts);
      });

      test('throws $LinkCreationException on an API error', () async {
        const error = LinkApiException('unavailable');
        when(
          () => api.createLink(
            code: any(named: 'code'),
            url: url,
          ),
        ).thenThrow(error);

        await expectLater(
          repository.shorten(url, ownHost: ownHost),
          throwsA(
            isA<LinkCreationException>().having(
              (exception) => exception.error,
              'error',
              error,
            ),
          ),
        );
        verify(
          () => api.createLink(
            code: any(named: 'code'),
            url: url,
          ),
        ).called(1);
      });
    });

    group('resolve', () {
      test('returns the stored URL', () async {
        when(() => api.getUrl(code)).thenAnswer((_) async => url);

        expect(await repository.resolve(code), equals(url));
      });

      test('returns an http URL', () async {
        when(() => api.getUrl(code))
            .thenAnswer((_) async => 'http://example.com');

        expect(await repository.resolve(code), equals('http://example.com'));
      });

      test('returns null when the link does not exist', () async {
        when(() => api.getUrl(code)).thenAnswer((_) async => null);

        expect(await repository.resolve(code), isNull);
      });

      test('returns null for a malformed code without reading', () async {
        expect(await repository.resolve('nope'), isNull);
        verifyZeroInteractions(api);
      });

      for (final stored in ['javascript:alert(1)', 'ftp://x.com', 'http://[']) {
        test('returns null when the stored URL is "$stored"', () async {
          when(() => api.getUrl(code)).thenAnswer((_) async => stored);

          expect(await repository.resolve(code), isNull);
        });
      }

      test('throws $LinkResolutionException on an API error', () async {
        const error = LinkApiException('unavailable');
        when(() => api.getUrl(code)).thenThrow(error);

        await expectLater(
          repository.resolve(code),
          throwsA(
            isA<LinkResolutionException>().having(
              (exception) => exception.error,
              'error',
              error,
            ),
          ),
        );
      });
    });
  });

  group(LinkCreationException, () {
    test('toString includes the error', () {
      expect(
        const LinkCreationException('boom').toString(),
        equals('LinkCreationException(boom)'),
      );
    });
  });

  group(LinkResolutionException, () {
    test('toString includes the error', () {
      expect(
        const LinkResolutionException('boom').toString(),
        equals('LinkResolutionException(boom)'),
      );
    });
  });
}
