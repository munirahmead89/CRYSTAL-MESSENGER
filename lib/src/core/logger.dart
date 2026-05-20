import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
  );

  static void d(String msg) => _logger.d(msg);
  static void i(String msg) => _logger.i(msg);
  static void w(String msg) => _logger.w(msg);
  static void e(String tag, [String? msg]) => _logger.e('$tag ${msg ?? ''}');
}
