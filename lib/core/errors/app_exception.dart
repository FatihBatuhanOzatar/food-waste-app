/// Base class for all application-specific exceptions.
///
/// All exceptions thrown from repositories and providers **must** extend
/// [AppException]. Never propagate raw [Exception] or [Error] subtypes
/// to the UI layer — always wrap them in a typed [AppException] subclass.
///
/// Because [AppException] is `sealed`, switch expressions over it
/// are exhaustive within this library and the compiler will flag
/// missing cases elsewhere.
sealed class AppException implements Exception {
  /// Creates an [AppException] with the given [message].
  const AppException(this.message);

  /// Human-readable description of the error (English, for logs and debugging).
  ///
  /// User-facing messages are produced by [ErrorHandler.toUserMessage].
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when an authentication operation fails.
///
/// Examples: invalid credentials, expired session, account not found,
/// email not confirmed.
final class AuthException extends AppException {
  /// Creates an [AuthException] with the given [message].
  const AuthException(super.message);
}

/// Thrown when a network or database operation fails.
///
/// Wraps [PostgrestException], connection timeouts, and similar I/O errors
/// so the rest of the app never depends on Supabase-specific exception types.
final class NetworkException extends AppException {
  /// Creates a [NetworkException] with the given [message].
  const NetworkException(super.message);
}

/// Thrown when user input fails validation before a network call is made.
///
/// Use this to surface field-level errors from repositories without
/// making a round-trip to the server.
final class ValidationException extends AppException {
  /// Creates a [ValidationException] with the given [message].
  ///
  /// Optionally specify a [field] name to indicate which input failed.
  const ValidationException(super.message, {this.field});

  /// The name of the form field that failed validation, if applicable.
  final String? field;
}

/// Thrown when a requested resource does not exist.
///
/// Examples: product not found, order ID does not belong to the current user.
final class NotFoundException extends AppException {
  /// Creates a [NotFoundException] with the given [message].
  const NotFoundException(super.message);
}
