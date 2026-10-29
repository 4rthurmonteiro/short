// Not required for test files
// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:link_repository/link_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:short/l10n/l10n.dart';
import 'package:short/redirect/redirect.dart';
import 'package:short/url_redirector/url_redirector.dart';

import '../../helpers/helpers.dart';

class _MockLinkRepository extends Mock implements LinkRepository;

class _MockUrlRedirector extends Mock implements UrlRedirector;

class _MockRedirectCubit extends MockCubit<RedirectState>
    implements RedirectCubit;

void main() {
  const code = 'aB3dE5g';
  const url = 'https://example.com/path';

  late UrlRedirector redirector;

  setUp(() {
    redirector = _MockUrlRedirector();
  });

  group(RedirectPage, () {
    late LinkRepository linkRepository;

    setUp(() {
      linkRepository = _MockLinkRepository();
    });

    testWidgets('loads the code and redirects to the stored url', (
      tester,
    ) async {
      when(() => linkRepository.resolve(code)).thenAnswer((_) async => url);

      await tester.pumpApp(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: linkRepository),
            RepositoryProvider.value(value: redirector),
          ],
          child: RedirectPage(code: code),
        ),
      );
      await tester.pump();

      verify(() => linkRepository.resolve(code)).called(1);
      verify(() => redirector.redirect(url)).called(1);
    });
  });

  group(RedirectView, () {
    late RedirectCubit cubit;

    setUp(() {
      cubit = _MockRedirectCubit();
      when(() => cubit.load(any())).thenAnswer((_) async {});
    });

    Widget buildSubject() => MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: redirector)],
      child: BlocProvider.value(
        value: cubit,
        child: const RedirectView(code: code),
      ),
    );

    testWidgets('shows a spinner while loading', (tester) async {
      when(() => cubit.state).thenReturn(const RedirectInProgress());

      await tester.pumpApp(buildSubject());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verifyNever(() => redirector.redirect(any()));
    });

    testWidgets('redirects and keeps the spinner when found', (tester) async {
      whenListen(
        cubit,
        Stream.value(const RedirectFound(url)),
        initialState: const RedirectInProgress(),
      );

      await tester.pumpApp(buildSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verify(() => redirector.redirect(url)).called(1);
    });

    testWidgets('shows the not-found view', (tester) async {
      when(() => cubit.state).thenReturn(const RedirectNotFound());

      await tester.pumpApp(buildSubject());

      expect(find.text('Link not found'), findsOneWidget);
      expect(find.text('Create a short link'), findsOneWidget);
    });

    testWidgets('not-found button goes to /', (tester) async {
      when(() => cubit.state).thenReturn(const RedirectNotFound());
      final router = GoRouter(
        initialLocation: '/$code',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(path: '/:code', builder: (_, _) => buildSubject()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create a short link'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('shows the failure view and retries', (tester) async {
      when(() => cubit.state).thenReturn(const RedirectFailure());

      await tester.pumpApp(buildSubject());

      expect(find.text("Couldn't load link"), findsOneWidget);
      await tester.tap(find.text('Retry'));

      verify(() => cubit.load(code)).called(1);
    });
  });
}
