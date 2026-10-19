class Environment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Absolute API base URL.
  ///
  /// When the build passes an empty `API_BASE_URL`, the app calls its own
  /// origin (e.g. behind a proxy or a Cloudflare tunnel where nginx routes
  /// `/api/` to the backend), so the same web build works on any host
  /// without rebuilding. Native (APK) builds always pass an explicit URL.
  static String get apiBase {
    final configured = apiBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/$'), '');
    }
    try {
      final origin = Uri.base.origin;
      if (origin.startsWith('http')) return origin;
    } catch (_) {
      // Non-web platforms without an explicit URL fall through.
    }
    return 'http://localhost:8000';
  }
}
