import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_repository/link_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:short/shortener/shortener.dart';

class _MockLinkRepository extends Mock implements LinkRepository;

void main() {
  const origin = 'https://short.test';
  const ownHost = 'short.test';
  const input = 'example.com';
  const code = 'aB3dE5g';

  group(ShortenerCubit, () {
    late LinkRepository linkRepository;

    setUp(() {
      linkRepository = _MockLinkRepository();
    });

    ShortenerCubit buildCubit() => ShortenerCubit(
      linkRepository: linkRepository,
      origin: origin,
      ownHost: ownHost,
    );

    test('initial state is $ShortenerInitial', () {
      expect(buildCubit().state, equals(const ShortenerInitial()));
    });

    group('submit', () {
      blocTest<ShortenerCubit, ShortenerState>(
        'emits [inProgress, success] with origin/code',
        setUp: () =>
            when(() => linkRepository.shorten(input, ownHost: ownHost))
                .thenAnswer((_) async => code),
        build: buildCubit,
        act: (cubit) => cubit.submit(input),
        expect: () => const [
          ShortenerInProgress(),
          ShortenerSuccess('$origin/$code'),
        ],
        verify: (_) =>
            verify(() => linkRepository.shorten(input, ownHost: ownHost))
                .called(1),
      );

      for (final reason in InvalidUrlReason.values) {
        blocTest<ShortenerCubit, ShortenerState>(
          'emits [inProgress, failure] for $reason',
          setUp: () =>
              when(() => linkRepository.shorten(input, ownHost: ownHost))
                  .thenThrow(InvalidUrlException(reason)),
          build: buildCubit,
          act: (cubit) => cubit.submit(input),
          expect: () => [
            const ShortenerInProgress(),
            ShortenerFailure(ShortenerInvalidUrl(reason)),
          ],
        );
      }

      blocTest<ShortenerCubit, ShortenerState>(
        'emits [inProgress, network failure] on $LinkCreationException',
        setUp: () =>
            when(() => linkRepository.shorten(input, ownHost: ownHost))
                .thenThrow(const LinkCreationException()),
        build: buildCubit,
        act: (cubit) => cubit.submit(input),
        expect: () => const [
          ShortenerInProgress(),
          ShortenerFailure(ShortenerNetworkFailure()),
        ],
      );

      blocTest<ShortenerCubit, ShortenerState>(
        'does nothing while in progress',
        build: buildCubit,
        seed: () => const ShortenerInProgress(),
        act: (cubit) => cubit.submit(input),
        expect: () => const <ShortenerState>[],
        verify: (_) => verifyNever(
          () => linkRepository.shorten(any(), ownHost: any(named: 'ownHost')),
        ),
      );

      blocTest<ShortenerCubit, ShortenerState>(
        'ignores a second submit made before the first finishes',
        setUp: () =>
            when(() => linkRepository.shorten(input, ownHost: ownHost))
                .thenAnswer((_) async => code),
        build: buildCubit,
        act: (cubit) => Future.wait([cubit.submit(input), cubit.submit(input)]),
        expect: () => const [
          ShortenerInProgress(),
          ShortenerSuccess('$origin/$code'),
        ],
        verify: (_) =>
            verify(() => linkRepository.shorten(input, ownHost: ownHost))
                .called(1),
      );

      blocTest<ShortenerCubit, ShortenerState>(
        'replaces a previous success',
        setUp: () =>
            when(() => linkRepository.shorten(input, ownHost: ownHost))
                .thenAnswer((_) async => 'zZ9yY8x'),
        build: buildCubit,
        seed: () => const ShortenerSuccess('$origin/$code'),
        act: (cubit) => cubit.submit(input),
        expect: () => const [
          ShortenerInProgress(),
          ShortenerSuccess('$origin/zZ9yY8x'),
        ],
      );
    });
  });
}
