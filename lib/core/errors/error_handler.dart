import 'app_exception.dart';

/// Maps application exceptions to Turkish user-facing error messages.
///
/// All UI error display must go through this class. Never show raw
/// exception messages or stack traces to the user.
///
/// **Usage:**
/// ```dart
/// error: (e, _) => ErrorView(ErrorHandler.toUserMessage(e)),
/// ```
abstract final class ErrorHandler {
  /// Converts an [error] object to a Turkish user-facing message string.
  ///
  /// Returns a generic fallback message for unrecognised error types
  /// so the UI always has something safe to display.
  static String toUserMessage(Object error) {
    return switch (error) {
      AuthException(message: final msg)
          when msg.contains('Invalid login credentials') =>
        'E-posta veya şifre hatalı. Lütfen tekrar deneyin.',
      AuthException(message: final msg)
          when msg.contains('Email not confirmed') =>
        'E-posta adresinizi doğrulayın. Gelen kutunuzu kontrol edin.',
      AuthException(message: final msg)
          when msg.contains('User already registered') =>
        'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin.',
      AuthException() => 'Kimlik doğrulama hatası. Lütfen tekrar giriş yapın.',
      NetworkException() =>
        'Bağlantı hatası. İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      ValidationException(field: final field) when field != null =>
        '"$field" alanı geçersiz. Lütfen kontrol edin.',
      ValidationException() =>
        'Girilen bilgilerde hata var. Lütfen tüm alanları kontrol edin.',
      NotFoundException() => 'Aradığınız içerik bulunamadı.',
      _ => 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
    };
  }
}
