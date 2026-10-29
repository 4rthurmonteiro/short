import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firestore_link_api/firestore_link_api.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:link_repository/link_repository.dart';
import 'package:short/firebase_options.dart';
import 'package:short/url_redirector/url_redirector.dart';

class AppBlocObserver extends BlocObserver {
  const new();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LinkRepository>(
          create: (_) => LinkRepository(
            api: FirestoreLinkApi(firestore: FirebaseFirestore.instance),
          ),
        ),
        RepositoryProvider<UrlRedirector>(create: (_) => UrlRedirector()),
      ],
      child: await builder(),
    ),
  );
}
