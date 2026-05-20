/// Base exception class for the app
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException(super.message);
}

/// Chat and messaging exceptions
class ChatException extends AppException {
  ChatException(super.message);
}

/// Storage and file exceptions
class StorageException extends AppException {
  StorageException(super.message);
}

/// Network and connectivity exceptions
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Generic app exceptions
class AppGenericException extends AppException {
  AppGenericException(super.message);
}
