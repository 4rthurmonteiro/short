import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_repository/link_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:short/redirect/redirect.dart';

class _MockLinkRepository extends Mock implements LinkRepository;

void main() {
  const code = 'aB3dE5g';
  const url = 'https://example.com/path';

  group(RedirectCubit, () {
    late LinkRepository linkRepository;

    setUp(() {
      linkRepository = _MockLinkRepository();
    });

    RedirectCubit buildCubit() => RedirectCubit(linkRepository: linkRepository);

    test('initial state is $RedirectInProgress', () {
      expect(buildCubit().state, equals(const RedirectInProgress()));
    });

    group('load', () {
      blocTest<RedirectCubit, RedirectState>(
        'emits $RedirectNotFound without reading for a malformed code',
        build: buildCubit,
        act: (cubit) => cubit.load('abc'),
        expect: () => const [RedirectNotFound()],
        verify: (_) => verifyNever(() => linkRepository.resolve(any())),
      );

      blocTest<RedirectCubit, RedirectState>(
        'emits $RedirectNotFound without reading for an empty code',
        build: buildCubit,
        act: (cubit) => cubit.load(''),
        expect: () => const [RedirectNotFound()],
        verify: (_) => verifyNever(() => linkRepository.resolve(any())),
      );

      blocTest<RedirectCubit, RedirectState>(
        'emits $RedirectFound when the link exists',
        setUp: () =>
            when(() => linkRepository.resolve(code))
                .thenAnswer((_) async => url),
        build: buildCubit,
        act: (cubit) => cubit.load(code),
        expect: () => const [RedirectInProgress(), RedirectFound(url)],
        verify: (_) => verify(() => linkRepository.resolve(code)).called(1),
      );

      blocTest<RedirectCubit, RedirectState>(
        'emits $RedirectNotFound when the link does not exist',
        setUp: () =>
            when(() => linkRepository.resolve(code))
                .thenAnswer((_) async => null),
        build: buildCubit,
        act: (cubit) => cubit.load(code),
        expect: () => const [RedirectInProgress(), RedirectNotFound()],
      );

      blocTest<RedirectCubit, RedirectState>(
        'emits $RedirectFailure when resolving fails',
        setUp: () =>
            when(() => linkRepository.resolve(code))
                .thenThrow(const LinkResolutionException('boom')),
        build: buildCubit,
        act: (cubit) => cubit.load(code),
        expect: () => const [RedirectInProgress(), RedirectFailure()],
      );

      blocTest<RedirectCubit, RedirectState>(
        'emits $RedirectInProgress then $RedirectFound on retry',
        setUp: () =>
            when(() => linkRepository.resolve(code))
                .thenAnswer((_) async => url),
        build: buildCubit,
        seed: () => const RedirectFailure(),
        act: (cubit) => cubit.load(code),
        expect: () => const [RedirectInProgress(), RedirectFound(url)],
      );
    });
  });

  group(RedirectFound, () {
    test('supports value equality', () {
      expect(const RedirectFound(url), equals(const RedirectFound(url)));
      expect(
        const RedirectFound(url),
        isNot(equals(const RedirectFound('https://other.com'))),
      );
    });
  });
}
