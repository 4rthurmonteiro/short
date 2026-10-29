import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:short/app/app.dart';
import 'package:short/shortener/shortener.dart';

void main() {
  group(App, () {
    testWidgets('renders $ShortenerPage at /', (tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      expect(find.byType(ShortenerPage), findsOneWidget);
    });

    testWidgets('keeps an injected router alive on dispose', (tester) async {
      final router = createRouter(initialLocation: '/');
      addTearDown(router.dispose);

      await tester.pumpWidget(App(router: router));
      await tester.pumpWidget(const SizedBox());

      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });
  });
}
