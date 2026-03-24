import '../services/remote_config_service.dart';

/// Input validation helpers for ClassMate.
/// All methods return a String error message, or null if valid.
abstract class AppValidators {

  // ── Email ────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final trimmed = value.trim().toLowerCase();
    // Basic format check
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) return 'Enter a valid email address';
    return null; // Format valid — domain check done separately
  }

  /// Validate that the email domain is on the allowlist.
  /// Checks both client-side and reads from Remote Config cached value.
  static String? emailDomain(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final trimmed = value.trim().toLowerCase();
    // Get allowed domains from Remote Config (falls back to hardcoded list)
    final domains = _getAllowedDomains();
    final isAllowed = domains.any((d) => trimmed.endsWith(d));
    if (!isAllowed) {
      return 'Only ${domains.join(' or ')} emails are allowed';
    }
    return null;
  }

  static List<String> _getAllowedDomains() {
    try {
      return RemoteConfigService.instance.getAllowedEmailDomains();
    } catch (_) {
      // Fallback if Remote Config not yet initialized
      return ['@marwadiuniversity.ac.in', '@gmail.com'];
    }
  }

  // ── Password ─────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  // ── Required ─────────────────────────────────────────────────
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  // ── Max length ───────────────────────────────────────────────
  static String? maxLength(String? value, int max, {String fieldName = 'Field'}) {
    if (value == null) return null;
    if (value.length > max) return '$fieldName must be under $max characters';
    return null;
  }

  // ── Phone ────────────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    if (digits.length > 15) return 'Phone number too long';
    return null;
  }

  // ── Compound: email + domain ─────────────────────────────────
  static String? registerEmail(String? value) {
    return email(value) ?? emailDomain(value);
  }
}
