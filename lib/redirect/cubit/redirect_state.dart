part of 'redirect_cubit.dart';

sealed class RedirectState extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

final class RedirectInProgress extends RedirectState {
  const new();
}

final class RedirectFound extends RedirectState {
  const new(this.url);

  final String url;

  @override
  List<Object> get props => [url];
}

final class RedirectNotFound extends RedirectState {
  const new();
}

final class RedirectFailure extends RedirectState {
  const new();
}
