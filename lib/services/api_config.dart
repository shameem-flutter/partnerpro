class ApiConfig {
  static const String defaultBaseUrl = 'https://partnerpro.saasorder.com';

  /// Gets the static base URL.
  static Future<String> getBaseUrl() async {
    return defaultBaseUrl;
  }

  /// Saves the new base URL (no-op since base URL is static).
  static Future<void> saveConfig(String baseUrl) async {
    // No-op
  }

  static bool _isLocalHost(String host) {
    final cleanHost = host.toLowerCase().trim();
    if (cleanHost.startsWith('localhost') ||
        cleanHost.startsWith('127.') ||
        cleanHost.startsWith('10.') ||
        cleanHost.startsWith('192.168.')) {
      return true;
    }
    // Check RFC1918 172.16.0.0 to 172.31.255.255
    if (cleanHost.startsWith('172.')) {
      final parts = cleanHost.split('.');
      if (parts.length > 1) {
        final secondPart = int.tryParse(parts[1]);
        if (secondPart != null && secondPart >= 16 && secondPart <= 31) {
          return true;
        }
      }
    }
    // Check local domains
    if (cleanHost.endsWith('.local') ||
        cleanHost.endsWith('.test') ||
        cleanHost.endsWith('.lan') ||
        cleanHost.endsWith('.vpn') ||
        cleanHost.endsWith('.internal')) {
      return true;
    }
    return false;
  }

  /// Constructs the full URL using dynamic baseUrl.
  static Future<String> getFullUrl(String path) async {
    var baseUrl = await getBaseUrl();
    
    // Trim whitespace
    baseUrl = baseUrl.trim();
    var cleanPath = path.trim();

    // If scheme is missing, prepend https:// (or http:// for localhost/emulators)
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      final isLocal = _isLocalHost(baseUrl);
      if (isLocal) {
        baseUrl = 'http://$baseUrl';
      } else {
        baseUrl = 'https://$baseUrl';
      }
    }

    // Auto-upgrade remote http:// to https:// to prevent 301/302 redirects from converting POST to GET
    if (baseUrl.startsWith('http://')) {
      final hostPart = baseUrl.substring(7);
      final hostWithoutPort = hostPart.split(':').first;
      final isLocal = _isLocalHost(hostWithoutPort);
      if (!isLocal) {
        baseUrl = 'https://$hostPart';
      }
    }

    // Ensure baseUrl doesn't have trailing slash
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    // Ensure path starts with a slash
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    // Ensure API path ends with a slash to prevent trailing slash redirects (which convert POST to GET)
    // Only append if it doesn't already have one and doesn't look like a file (e.g. file.json)
    if (!cleanPath.endsWith('/')) {
      final lastSegment = cleanPath.split('/').last;
      if (!lastSegment.contains('.')) {
        cleanPath = '$cleanPath/';
      }
    }
    
    return '$baseUrl$cleanPath';
  }
}
