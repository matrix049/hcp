/// Resolves a localized label map to a display string.
///
/// Tries the requested [locale], then a sensible fallback order (fr → ar → en),
/// then the '*' plain-string key, then any available value.
String localizedText(Map<String, String> labels, {String locale = 'fr'}) {
  if (labels.isEmpty) return '';
  for (final key in [locale, 'fr', 'ar', 'en', '*']) {
    final value = labels[key];
    if (value != null && value.isNotEmpty) return value;
  }
  return labels.values.first;
}
