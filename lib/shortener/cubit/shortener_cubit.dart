import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:link_repository/link_repository.dart';

part 'shortener_state.dart';

class ShortenerCubit extends Cubit<ShortenerState> {
  /// `baseUri` is the app's own URL: its origin is prepended to the code to
  /// build the short URL, and links pointing at its host are rejected.
  new({required this._linkRepository, required this._baseUri})
    : super(const ShortenerInitial());

  final LinkRepository _linkRepository;
  final Uri _baseUri;

  /// Shortens [input]. Does nothing while a request is in progress.
  Future<void> submit(String input) async {
    if (state is ShortenerInProgress) return;
    emit(const ShortenerInProgress());
    try {
      final code = await _linkRepository.shorten(input, ownHost: _baseUri.host);
      emit(ShortenerSuccess('${_baseUri.origin}/$code'));
    } on InvalidUrlException catch (exception) {
      emit(ShortenerFailure(ShortenerInvalidUrl(exception.reason)));
    } on LinkCreationException {
      emit(const ShortenerFailure(ShortenerNetworkFailure()));
    }
  }
}
