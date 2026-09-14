class ApiConfig {
  /// Base URL used by the Normal User features (login, orders, dashboard, etc.)
  static const String defaultBaseUrl =
      'https://mega-ahead-hampshire-disclosure.trycloudflare.com/';

  /// Base URL used by the Admin features
  /// (all-salesperson-orders, all-referral-orders, sales-report, etc.)
  static const String adminBaseUrl =
      'https://mega-ahead-hampshire-disclosure.trycloudflare.com/';

  // --------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Gets the static base URL for normal-user endpoints.
  static Future<String> getBaseUrl() async {
    return defaultBaseUrl;
  }

  /// Gets the static base URL for admin endpoints.
  static Future<String> getAdminBaseUrl() async {
    return adminBaseUrl;
  }

  /// Saves the new base URL (no-op since base URL is static).
  static Future<void> saveConfig(String baseUrl) async {
    // No-op
  }

  // ---------------------------------------------------------------------------
  // URL construction
  // ---------------------------------------------------------------------------

  /// Constructs the full URL using the normal-user [defaultBaseUrl].
  static Future<String> getFullUrl(String path) async {
    final baseUrl = await getBaseUrl();
    return _buildUrl(baseUrl, path);
  }

  /// Constructs the full URL using the [adminBaseUrl].
  static Future<String> getAdminFullUrl(String path) async {
    final baseUrl = await getAdminBaseUrl();
    return _buildUrl(baseUrl, path);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _buildUrl(String baseUrl, String path) {
    var cleanBase = baseUrl.trim();
    var cleanPath = path.trim();

    // If scheme is missing, prepend https:// (or http:// for localhost/emulators)
    if (!cleanBase.startsWith('http://') && !cleanBase.startsWith('https://')) {
      final isLocal = _isLocalHost(cleanBase);
      cleanBase = isLocal ? 'http://$cleanBase' : 'https://$cleanBase';
    }

    // Auto-upgrade remote http:// to https:// to prevent redirect issues
    if (cleanBase.startsWith('http://')) {
      final hostPart = cleanBase.substring(7);
      final hostWithoutPort = hostPart.split(':').first;
      if (!_isLocalHost(hostWithoutPort)) {
        cleanBase = 'https://$hostPart';
      }
    }

    // Strip trailing slash from base
    if (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }

    // Ensure path starts with /
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    // Ensure path ends with / (prevents trailing-slash redirects converting POST to GET)
    if (!cleanPath.endsWith('/')) {
      final lastSegment = cleanPath.split('/').last;
      if (!lastSegment.contains('.')) {
        cleanPath = '$cleanPath/';
      }
    }

    return '$cleanBase$cleanPath';
  }

  static bool _isLocalHost(String host) {
    final cleanHost = host.toLowerCase().trim();
    if (cleanHost.startsWith('localhost') ||
        cleanHost.startsWith('127.') ||
        cleanHost.startsWith('10.') ||
        cleanHost.startsWith('192.168.')) {
      return true;
    }
    // RFC1918 172.16.0.0–172.31.255.255
    if (cleanHost.startsWith('172.')) {
      final parts = cleanHost.split('.');
      if (parts.length > 1) {
        final secondPart = int.tryParse(parts[1]);
        if (secondPart != null && secondPart >= 16 && secondPart <= 31) {
          return true;
        }
      }
    }
    if (cleanHost.endsWith('.local') ||
        cleanHost.endsWith('.test') ||
        cleanHost.endsWith('.lan') ||
        cleanHost.endsWith('.vpn') ||
        cleanHost.endsWith('.internal')) {
      return true;
    }
    return false;
  }
}
