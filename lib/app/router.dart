import 'package:go_router/go_router.dart';
import 'package:short/redirect/redirect.dart';
import 'package:short/shortener/shortener.dart';

/// Creates the app's router.
///
/// `/` shows the shortener and `/:code` resolves a short link. Any other
/// path shows the redirect page with an empty code, which is never valid,
/// so it renders "Link not found" without reading Firestore.
GoRouter createRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) => state.uri.path == '/index.html' ? '/' : null,
    errorBuilder: (context, state) => const RedirectPage(code: ''),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ShortenerPage()),
      GoRoute(
        path: '/:code',
        builder: (context, state) =>
            RedirectPage(code: state.pathParameters['code']!),
      ),
    ],
  );
}
