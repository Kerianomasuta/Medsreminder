import 'api_base_url_stub.dart'
    if (dart.library.js_interop) 'api_base_url_web.dart'
    as platform;

const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl => _configuredBaseUrl.isNotEmpty
    ? _configuredBaseUrl
    : platform.defaultApiBaseUrl();
