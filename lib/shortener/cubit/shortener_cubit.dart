import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:link_repository/link_repository.dart';

part 'shortener_state.dart';

class ShortenerCubit extends Cubit<ShortenerState> {
  /// `origin` is prepended to the code to build the short URL, and links
  /// pointing at `ownHost` are rejected.
  new({
    required this._linkRepository,
    required this._origin,
    required this._ownHost,
  }) : super(const ShortenerInitial());

  final LinkRepository _linkRepository;
  final String _origin;
  final String _ownHost;

  /// Shortens [input]. Does nothing while a request is in progress.
  Future<void> submit(String input) async {
    if (state is ShortenerInProgress) return;
    emit(const ShortenerInProgress());
    try {
      final code = await _linkRepository.shorten(input, ownHost: _ownHost);
      emit(ShortenerSuccess('$_origin/$code'));
    } on InvalidUrlException catch (exception) {
      emit(ShortenerFailure(ShortenerInvalidUrl(exception.reason)));
    } on LinkCreationException {
      emit(const ShortenerFailure(ShortenerNetworkFailure()));
    }
  }
}
