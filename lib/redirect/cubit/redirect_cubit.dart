import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:link_repository/link_repository.dart';

part 'redirect_state.dart';

class RedirectCubit extends Cubit<RedirectState> {
  new({required this._linkRepository}) : super(const RedirectInProgress());

  final LinkRepository _linkRepository;

  Future<void> load(String code) async {
    if (!LinkRepository.isValidCode(code)) {
      emit(const RedirectNotFound());
      return;
    }
    emit(const RedirectInProgress());
    try {
      final url = await _linkRepository.resolve(code);
      emit(url == null ? const RedirectNotFound() : RedirectFound(url));
    } on LinkResolutionException {
      emit(const RedirectFailure());
    }
  }
}
