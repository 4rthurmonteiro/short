import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_repository/link_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:short/app/app.dart';
import 'package:short/shortener/shortener.dart';

class _MockLinkRepository extends Mock implements LinkRepository;

void main() {
  group(App, () {
    testWidgets('renders $ShortenerPage at /', (tester) async {
      await tester.pumpWidget(
        RepositoryProvider<LinkRepository>(
          create: (_) => _MockLinkRepository(),
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShortenerPage), findsOneWidget);
    });

    testWidgets('keeps an injected router alive on dispose', (tester) async {
      final router = createRouter(initialLocation: '/');
      addTearDown(router.dispose);

      await tester.pumpWidget(
        RepositoryProvider<LinkRepository>(
          create: (_) => _MockLinkRepository(),
          child: App(router: router),
        ),
      );
      await tester.pumpWidget(const SizedBox());

      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });
  });
}
