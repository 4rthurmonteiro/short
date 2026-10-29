part of 'shortener_cubit.dart';

/// Why a submit failed.
sealed class ShortenerFailureReason extends Equatable {
  const new();
}

/// The input was rejected before anything was written.
final class ShortenerInvalidUrl extends ShortenerFailureReason {
  const new(this.reason);

  final InvalidUrlReason reason;

  @override
  List<Object> get props => [reason];
}

/// The link couldn't be stored.
final class ShortenerNetworkFailure extends ShortenerFailureReason {
  const new();

  @override
  List<Object> get props => [];
}

sealed class ShortenerState extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

final class ShortenerInitial extends ShortenerState {
  const new();
}

final class ShortenerInProgress extends ShortenerState {
  const new();
}

final class ShortenerSuccess extends ShortenerState {
  const new(this.shortUrl);

  final String shortUrl;

  @override
  List<Object> get props => [shortUrl];
}

final class ShortenerFailure extends ShortenerState {
  const new(this.reason);

  final ShortenerFailureReason reason;

  @override
  List<Object> get props => [reason];
}
