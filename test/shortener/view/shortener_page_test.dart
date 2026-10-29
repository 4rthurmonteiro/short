import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:link_repository/link_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:short/shortener/shortener.dart';

import '../../helpers/helpers.dart';

class _MockLinkRepository extends Mock implements LinkRepository;

class _MockShortenerCubit extends MockCubit<ShortenerState>
    implements ShortenerCubit;

void main() {
  const shortUrl = 'https://short.test/aB3dE5g';

  group(ShortenerPage, () {
    testWidgets('shortens using the base URI origin and host', (tester) async {
      final linkRepository = _MockLinkRepository();
      when(() => linkRepository.shorten('example.com', ownHost: 'short.test'))
          .thenAnswer((_) async => 'aB3dE5g');

      await tester.pumpApp(
        RepositoryProvider<LinkRepository>.value(
          value: linkRepository,
          child: ShortenerPage(baseUri: Uri.parse('https://short.test/')),
        ),
      );
      await tester.enterText(find.byType(TextField), 'example.com');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text(shortUrl), findsOneWidget);
    });
  });

  group(ShortenerView, () {
    late ShortenerCubit cubit;

    setUp(() {
      cubit = _MockShortenerCubit();
      when(() => cubit.state).thenReturn(const ShortenerInitial());
      when(() => cubit.submit(any())).thenAnswer((_) async {});
    });

    Future<void> pumpView(WidgetTester tester) => tester.pumpApp(
      BlocProvider.value(value: cubit, child: const ShortenerView()),
    );

    FilledButton submitButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byType(FilledButton));

    testWidgets('disables submit while the field is empty or blank', (
      tester,
    ) async {
      await pumpView(tester);
      expect(submitButton(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(submitButton(tester).onPressed, isNull);

      await tester.testTextInput.receiveAction(TextInputAction.go);
      verifyNever(() => cubit.submit(any()));
    });

    testWidgets('submits on tap', (tester) async {
      await pumpView(tester);
      await tester.enterText(find.byType(TextField), 'example.com');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));

      verify(() => cubit.submit('example.com')).called(1);
    });

    testWidgets('submits on Enter', (tester) async {
      await pumpView(tester);
      await tester.enterText(find.byType(TextField), 'example.com');
      await tester.testTextInput.receiveAction(TextInputAction.go);

      verify(() => cubit.submit('example.com')).called(1);
    });

    testWidgets('shows a spinner and disables submit while in progress', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(const ShortenerInProgress());
      await pumpView(tester);
      await tester.enterText(find.byType(TextField), 'example.com');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(submitButton(tester).onPressed, isNull);
    });

    final errors = <ShortenerFailureReason, String>{
      const ShortenerInvalidUrl(InvalidUrlReason.empty): 'Enter a URL',
      const ShortenerInvalidUrl(InvalidUrlReason.unsupportedScheme):
          'Only http and https links are supported',
      const ShortenerInvalidUrl(InvalidUrlReason.malformed):
          "That doesn't look like a valid URL",
      const ShortenerInvalidUrl(InvalidUrlReason.tooLong):
          'That URL is too long',
      const ShortenerInvalidUrl(InvalidUrlReason.selfLink):
          "That's already a short link",
      const ShortenerNetworkFailure(): "Couldn't create the link. Try again.",
    };
    for (final MapEntry(key: reason, value: message) in errors.entries) {
      testWidgets('shows an inline error for $reason', (tester) async {
        when(() => cubit.state).thenReturn(ShortenerFailure(reason));
        await pumpView(tester);

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.decoration?.errorText, equals(message));
      });
    }

    testWidgets('shows the short URL on success', (tester) async {
      when(() => cubit.state).thenReturn(const ShortenerSuccess(shortUrl));
      await pumpView(tester);

      expect(find.widgetWithText(SelectableText, shortUrl), findsOneWidget);
    });

    testWidgets('replaces the result and keeps the input on resubmit', (
      tester,
    ) async {
      whenListen(
        cubit,
        Stream.fromIterable(const [
          ShortenerSuccess(shortUrl),
          ShortenerInProgress(),
          ShortenerSuccess('https://short.test/zZ9yY8x'),
        ]),
        initialState: const ShortenerInitial(),
      );
      await pumpView(tester);
      await tester.enterText(find.byType(TextField), 'example.com');
      await tester.pumpAndSettle();

      expect(find.text(shortUrl), findsNothing);
      expect(find.text('https://short.test/zZ9yY8x'), findsOneWidget);
      expect(find.text('example.com'), findsOneWidget);
    });

    group('copy', () {
      setUp(() {
        when(() => cubit.state).thenReturn(const ShortenerSuccess(shortUrl));
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      testWidgets('copies the short URL and shows a SnackBar', (tester) async {
        Object? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') copied = call.arguments;
            return null;
          },
        );
        await pumpView(tester);
        await tester.tap(find.text('Copy'));
        await tester.pump();

        expect(copied, equals({'text': shortUrl}));
        expect(find.text('Copied!'), findsOneWidget);
      });

      testWidgets('shows a fallback SnackBar when copying fails', (
        tester,
      ) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              throw PlatformException(code: 'denied');
            }
            return null;
          },
        );
        await pumpView(tester);
        await tester.tap(find.text('Copy'));
        await tester.pump();

        expect(
          find.text("Couldn't copy. Select the link and copy it manually."),
          findsOneWidget,
        );
      });
    });
  });
}
