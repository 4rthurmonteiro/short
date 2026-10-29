import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_link_api/firestore_link_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore;

// The Firestore references are annotated @sealed, but mocking them is the only
// way to get a request that never completes.
// ignore: subtype_of_sealed_class
class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>>;

// Same as above.
// ignore: subtype_of_sealed_class
class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>>;

void main() {
  const code = 'aB3dE5g';
  const url = 'https://example.com/path';

  group(FirestoreLinkApi, () {
    late FakeFirebaseFirestore firestore;
    late FirestoreLinkApi api;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      api = FirestoreLinkApi(firestore: firestore);
    });

    DocumentReference<Map<String, dynamic>> linkDoc() =>
        firestore.collection('links').doc(code);

    group('createLink', () {
      test('writes exactly url and a server createdAt', () async {
        await api.createLink(code: code, url: url);

        final data = (await linkDoc().get()).data();
        expect(data, isNotNull);
        expect(data!.keys, unorderedEquals(['url', 'createdAt']));
        expect(data['url'], equals(url));
        expect(data['createdAt'], isA<Timestamp>());
      });

      test('throws $LinkCodeTakenException on permission-denied', () async {
        whenCalling(Invocation.method(#set, null))
            .on(linkDoc())
            .thenThrow(
              FirebaseException(
                plugin: 'cloud_firestore',
                code: 'permission-denied',
              ),
            );

        await expectLater(
          api.createLink(code: code, url: url),
          throwsA(
            isA<LinkCodeTakenException>().having(
              (exception) => exception.code,
              'code',
              code,
            ),
          ),
        );
      });

      test('throws $LinkApiException on other Firebase errors', () async {
        final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
        whenCalling(Invocation.method(#set, null))
            .on(linkDoc())
            .thenThrow(error);

        await expectLater(
          api.createLink(code: code, url: url),
          throwsA(
            isA<LinkApiException>().having(
              (exception) => exception.error,
              'error',
              error,
            ),
          ),
        );
      });
    });

    group('getUrl', () {
      test('returns the stored url', () async {
        await linkDoc().set({'url': url});

        expect(await api.getUrl(code), equals(url));
      });

      test('returns null when the doc does not exist', () async {
        expect(await api.getUrl(code), isNull);
      });

      test('returns null when url is not a string', () async {
        await linkDoc().set({'url': 42});

        expect(await api.getUrl(code), isNull);
      });

      test('throws $LinkApiException on Firebase errors', () async {
        whenCalling(Invocation.method(#get, null))
            .on(linkDoc())
            .thenThrow(
              FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
            );

        await expectLater(api.getUrl(code), throwsA(isA<LinkApiException>()));
      });
    });
  });

  group('$FirestoreLinkApi timeouts', () {
    late _MockDocumentReference document;
    late FirestoreLinkApi api;

    setUp(() {
      final firestore = _MockFirebaseFirestore();
      final collection = _MockCollectionReference();
      document = _MockDocumentReference();
      when(() => firestore.collection('links')).thenReturn(collection);
      when(() => collection.doc(code)).thenReturn(document);
      api = FirestoreLinkApi(firestore: firestore);
    });

    test('createLink throws $LinkApiException after the timeout', () {
      when(() => document.set(any()))
          .thenAnswer((_) => Completer<void>().future);

      fakeAsync((async) {
        Object? error;
        unawaited(
          api.createLink(code: code, url: url).catchError((Object e) {
            error = e;
          }),
        );

        async.elapse(
          FirestoreLinkApi.timeout - const Duration(milliseconds: 1),
        );
        expect(error, isNull);

        async.elapse(const Duration(milliseconds: 1));
        expect(
          error,
          isA<LinkApiException>().having(
            (exception) => exception.error,
            'error',
            isA<TimeoutException>(),
          ),
        );
      });
    });

    test('getUrl throws $LinkApiException after the timeout', () {
      when(document.get).thenAnswer(
        (_) => Completer<DocumentSnapshot<Map<String, dynamic>>>().future,
      );

      fakeAsync((async) {
        Object? error;
        unawaited(
          api.getUrl(code).then<void>((_) {}).catchError((Object e) {
            error = e;
          }),
        );

        async.elapse(FirestoreLinkApi.timeout);
        expect(
          error,
          isA<LinkApiException>().having(
            (exception) => exception.error,
            'error',
            isA<TimeoutException>(),
          ),
        );
      });
    });
  });

  group(LinkApiException, () {
    test('toString includes the error', () {
      expect(
        const LinkApiException('boom').toString(),
        equals('LinkApiException(boom)'),
      );
    });
  });

  group(LinkCodeTakenException, () {
    test('toString includes the code', () {
      expect(
        const LinkCodeTakenException(code).toString(),
        equals('LinkCodeTakenException($code)'),
      );
    });
  });
}
