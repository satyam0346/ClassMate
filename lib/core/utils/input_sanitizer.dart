/// Input sanitizer — strips HTML/script tags and dangerous characters
/// from all user-provided text before writing to Firestore.
///
/// Called in every controller before a Firestore write.
abstract class InputSanitizer {

  // ── Strip HTML / script tags ─────────────────────────────────
  /// Removes all HTML tags from input (e.g. <script>, <b>, <img ...>).
  static String stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '');
  }

  // ── Sanitize a general text field ────────────────────────────
  /// Trims whitespace, strips HTML tags, and collapses multiple spaces.
  static String sanitizeText(String input) {
    var result = input.trim();
    result = stripHtml(result);
    // Collapse multiple consecutive whitespace characters
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ');
    return result;
  }

  // ── Sanitize a title (single line) ───────────────────────────
  /// Same as sanitizeText but also removes newlines.
  static String sanitizeTitle(String input, {int maxLength = 200}) {
    var result = sanitizeText(input);
    result = result.replaceAll(RegExp(r'[\r\n]'), ' ');
    if (result.length > maxLength) {
      result = result.substring(0, maxLength);
    }
    return result;
  }

  // ── Sanitize a description (multi-line) ──────────────────────
  static String sanitizeDescription(String input, {int maxLength = 1000}) {
    var result = sanitizeText(input);
    if (result.length > maxLength) {
      result = result.substring(0, maxLength);
    }
    return result;
  }

  // ── Sanitize a URL ───────────────────────────────────────────
  /// Ensures only http/https URLs are accepted.
  static String? sanitizeUrl(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final trimmed = input.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return null; // Reject non-HTTP URLs (blocks javascript:, data:, etc.)
    }
    return trimmed;
  }

  // ── Build a sanitized Firestore map ──────────────────────────
  /// Convenience: sanitize a Map<String, dynamic> for Firestore writes.
  /// Applies sanitizeText to all String values, leaves non-strings untouched.
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String) return MapEntry(key, sanitizeText(value));
      return MapEntry(key, value);
    });
  }
}
