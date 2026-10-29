import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:link_repository/link_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:short/app/app.dart';
import 'package:short/redirect/redirect.dart';
import 'package:short/shortener/shortener.dart';

class _MockLinkRepository extends Mock implements LinkRepository;

void main() {
  group('createRouter', () {
    late LinkRepository linkRepository;

    setUp(() {
      linkRepository = _MockLinkRepository();
      when(() => linkRepository.resolve(any())).thenAnswer((_) async => null);
    });

    Future<GoRouter> pumpRouter(WidgetTester tester, String location) async {
      final router = createRouter(initialLocation: location);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepositoryProvider.value(
          value: linkRepository,
          child: App(router: router),
        ),
      );
      await tester.pumpAndSettle();
      return router;
    }

    RedirectPage redirectPage(WidgetTester tester) =>
        tester.widget<RedirectPage>(find.byType(RedirectPage));

    testWidgets('/ shows $ShortenerPage', (tester) async {
      await pumpRouter(tester, '/');

      expect(find.byType(ShortenerPage), findsOneWidget);
    });

    testWidgets('/index.html redirects to /', (tester) async {
      final router = await pumpRouter(tester, '/index.html');

      expect(find.byType(ShortenerPage), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.path, equals('/'));
    });

    testWidgets('/:code shows $RedirectPage with the code', (tester) async {
      await pumpRouter(tester, '/aB3dE5g');

      expect(find.byType(ShortenerPage), findsNothing);
      expect(redirectPage(tester).code, equals('aB3dE5g'));
    });

    testWidgets('/:code/ with a trailing slash matches /:code', (tester) async {
      await pumpRouter(tester, '/aB3dE5g/');

      expect(redirectPage(tester).code, equals('aB3dE5g'));
    });

    testWidgets('multi-segment paths show $RedirectPage with an empty code', (
      tester,
    ) async {
      await pumpRouter(tester, '/foo/bar');

      expect(find.byType(ShortenerPage), findsNothing);
      expect(redirectPage(tester).code, isEmpty);
    });
  });
}
