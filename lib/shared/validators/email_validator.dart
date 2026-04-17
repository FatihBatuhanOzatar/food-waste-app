/// Validator utilities for e-mail addresses.
///
/// Used by auth forms before making any network calls.
/// Returns `null` when the value is valid, or a Turkish error message string.
class EmailValidator {
  EmailValidator._();

  // RFC 5322-simplified pattern — sufficient for MVP validation.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  /// Returns `null` if [value] is a valid e-mail address,
  /// otherwise returns a Turkish validation error message.
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi boş bırakılamaz.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin.';
    }
    return null;
  }
}
