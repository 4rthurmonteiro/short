import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:link_repository/link_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:short/l10n/l10n.dart';
import 'package:short/redirect/redirect.dart';
import 'package:short/url_redirector/url_redirector.dart';

class RedirectPage extends StatelessWidget {
  const new({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = RedirectCubit(
          linkRepository: context.read<LinkRepository>(),
        );
        unawaited(cubit.load(code));
        return cubit;
      },
      child: RedirectView(code: code),
    );
  }
}

class RedirectView extends StatelessWidget {
  const new({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return BlocListener<RedirectCubit, RedirectState>(
      listener: (context, state) {
        if (state is RedirectFound) {
          context.read<UrlRedirector>().redirect(state.url);
        }
      },
      child: Scaffold(
        body: Center(
          child: BlocBuilder<RedirectCubit, RedirectState>(
            builder: (context, state) => switch (state) {
              RedirectInProgress() ||
              RedirectFound() => const CircularProgressIndicator(),
              RedirectNotFound() => const _NotFound(),
              RedirectFailure() => _Failure(code: code),
            },
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.redirectNotFoundTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.go('/'),
          child: Text(l10n.redirectCreateLinkButton),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const new({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.redirectFailureTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.read<RedirectCubit>().load(code),
          child: Text(l10n.redirectRetryButton),
        ),
      ],
    );
  }
}
