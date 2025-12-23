import 'dart:developer';

class AppLogger {
  static void info(String message) {
    log('INFO: $message');
  }

  static void success(String message) {
    log('SUCCESS: $message');
  }

  static void warning(String message) {
    log('WARNING: $message');
  }

  static void error(String message, [Object? error]) {
    log('ERROR: $message');
    if (error != null) {
      log('ERROR DETAILS: $error');
    }
  }

  static void api(String message) {
    log('API: $message');
  }

  static void auth(String message) {
    log('AUTH: $message');
  }
}
