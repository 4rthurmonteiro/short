import 'package:short/app/app.dart';
import 'package:short/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
