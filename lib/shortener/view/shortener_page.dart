import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:link_repository/link_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:short/l10n/l10n.dart';
import 'package:short/shortener/shortener.dart';

class ShortenerPage extends StatelessWidget {
  /// [baseUri] defaults to [Uri.base]; tests pass an http URI because
  /// [Uri.origin] throws for the `file:` URI used under `flutter test`.
  const new({this.baseUri, super.key});

  final Uri? baseUri;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShortenerCubit(
        linkRepository: context.read<LinkRepository>(),
        baseUri: baseUri ?? Uri.base,
      ),
      child: const ShortenerView(),
    );
  }
}

class ShortenerView extends StatefulWidget {
  const new({super.key});

  @override
  State<ShortenerView> createState() => _ShortenerViewState();
}

class _ShortenerViewState extends State<ShortenerView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _controller.text;
    if (input.trim().isEmpty) return;
    unawaited(context.read<ShortenerCubit>().submit(input));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<ShortenerCubit>().state;
    final inProgress = state is ShortenerInProgress;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l10n.shortenerUrlLabel,
                    errorText: switch (state) {
                      ShortenerFailure(:final reason) => reason.message(l10n),
                      _ => null,
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final canSubmit =
                        !inProgress && _controller.text.trim().isNotEmpty;
                    return FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      child: inProgress
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.shortenerSubmitButton),
                    );
                  },
                ),
                if (state case ShortenerSuccess(:final shortUrl)) ...[
                  const SizedBox(height: 24),
                  ShortUrlResult(shortUrl: shortUrl),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShortUrlResult extends StatelessWidget {
  const new({required this.shortUrl, super.key});

  final String shortUrl;

  Future<void> _copy(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      await Clipboard.setData(ClipboardData(text: shortUrl));
      message = l10n.shortenerCopiedMessage;
    } on Exception {
      message = l10n.shortenerCopyFailedMessage;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SelectableText(shortUrl)),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy),
          label: Text(context.l10n.shortenerCopyButton),
        ),
      ],
    );
  }
}

extension on ShortenerFailureReason {
  String message(AppLocalizations l10n) => switch (this) {
    ShortenerInvalidUrl(reason: InvalidUrlReason.empty) =>
      l10n.shortenerErrorEmpty,
    ShortenerInvalidUrl(reason: InvalidUrlReason.unsupportedScheme) =>
      l10n.shortenerErrorUnsupportedScheme,
    ShortenerInvalidUrl(reason: InvalidUrlReason.malformed) =>
      l10n.shortenerErrorMalformed,
    ShortenerInvalidUrl(reason: InvalidUrlReason.tooLong) =>
      l10n.shortenerErrorTooLong,
    ShortenerInvalidUrl(reason: InvalidUrlReason.selfLink) =>
      l10n.shortenerErrorSelfLink,
    ShortenerNetworkFailure() => l10n.shortenerErrorNetwork,
  };
}
